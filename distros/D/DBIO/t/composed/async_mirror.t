# ABSTRACT: async mirror composition, capabilities, '?' seam contract
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Scalar::Util ();

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::Storage::DBI;
use DBIO::Storage::Async;
use DBIO::Storage::Composed;
use DBIO::SQLMaker;

# ---------------------------------------------------------------------------
# A reusable dummy transport: a concrete DBIO::Storage::Async that records the
# SQL its query seam receives, with an IDENTITY _transform_sql (its wire speaks
# '?' -- so the placeholders must arrive unchanged from _run_crud).
# ---------------------------------------------------------------------------
{
  package T::AM::RecordingTransport;
  use base 'DBIO::Storage::Async';
  use mro 'c3';

  our @RECORDED;
  sub future_class     { 'DBIO::Test::Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _transform_sql   { $_[1] }        # identity: wire speaks '?'
  sub _post_insert_sql { '' }
  sub _query_async     { push @RECORDED, $_[1]; return DBIO::Test::Future->done }
  sub pool             { $_[0]->{pool} ||= bless {}, 'T::AM::NoPool' }
}

# Build a fresh sync storage for one scenario. $mode is the async mode string;
# the transport is registered against it on the sync storage class so
# _async_storage resolves it from the registry (explicit mode -- ADR 0030),
# except the one future_io scenario which resolves it by convention. Returns
# ($storage, $schema); the caller MUST hold $schema in scope -- storage weakens
# its schema back-reference, so a dropped schema would undef $self->schema
# inside _async_storage.
sub build_storage {
  my (%arg) = @_;
  my $schema = DBIO::Test->init_schema;
  $schema->register_storage_layer($_) for @{ $arg{layers} || [] };

  my $storage_class = $arg{storage_class};
  my $storage = $storage_class->new($schema);
  $storage->connect_info([ 'dbi:AMMock:', '', '', { async => $arg{mode} } ]);
  return ($storage, $schema);
}

# ===========================================================================
# Scenario 1 (future_io, convention transport): one layer WITH ::Async and one
# declared sync-only -> the backend is composed with exactly the one async layer.
#
# LayerB used to be merely silent (no ::Async, no declaration) and this
# scenario asserted it was skipped without a word. karr k159 step 3 REPLACES
# that claim: silent-and-absent is now refused (scenario 5), so LayerB states
# its sync-only status the way a real sync-only extension must.
# ===========================================================================
{
  package T::AM::S1::Storage;         use base 'DBIO::Test::Storage'; use mro 'c3';
  package T::AM::S1::Storage::Async;  use base 'T::AM::RecordingTransport'; use mro 'c3';

  package T::AM::S1::LayerA;          sub layer_a { 'a' }
  package T::AM::S1::LayerA::Async;   sub async_a { 'aa' }   # the async mirror
  package T::AM::S1::LayerB;          sub layer_b { 'b' }    # NO ::Async sibling
  sub async_layer_class { undef }                             # stated sync-only
}

{
  my ($storage, $schema) = build_storage(
    storage_class => 'T::AM::S1::Storage',
    mode          => 'future_io',
    layers        => [ 'T::AM::S1::LayerA', 'T::AM::S1::LayerB' ],
  );

  my $async = $storage->async;
  isa_ok $async, 'T::AM::S1::Storage::Async',
    'future_io resolved the transport by convention';
  isa_ok $async, 'T::AM::S1::LayerA::Async',
    'the WITH-::Async layer was mirrored and composed in';
  can_ok $async, 'async_a';

  ok !$async->isa('T::AM::S1::LayerB'),
    'the sync-only layer (no ::Async) is not composed into the async backend';
  ok !$async->can('layer_b'),
    'sync-only layer methods are absent from the async backend';

  is_deeply [ DBIO::Storage::Composed->layers_of(ref $async) ],
    [ 'T::AM::S1::LayerA::Async' ],
    'exactly one async layer composed over the transport';

  # --- WP3 '?' seam contract: _run_crud hands the transport raw sql_maker
  # output with '?' placeholders (its _transform_sql is identity) ----------
  @T::AM::RecordingTransport::RECORDED = ();
  $async->select_async('artist', [ '*' ], { id => 5 });
  my $sql = $T::AM::RecordingTransport::RECORDED[-1];
  ok defined $sql, 'the transport recorded a query from _run_crud';
  like $sql, qr/\?/,  'placeholders arrive at the seam as ? (sql_maker dialect)';
  unlike $sql, qr/\$\d/, 'core applied no $N dialect shaping';
}

# The same transport/layer recipe produces identical synthesized classes for
# independent storage objects. Ownership therefore has to follow the concrete
# owner/backend generation, not class shape or connect_info.
{
  my ($storage_a, $schema_a) = build_storage(
    storage_class => 'T::AM::S1::Storage',
    mode          => 'future_io',
    layers        => [ 'T::AM::S1::LayerA', 'T::AM::S1::LayerB' ],
  );
  my ($storage_b, $schema_b) = build_storage(
    storage_class => 'T::AM::S1::Storage',
    mode          => 'future_io',
    layers        => [ 'T::AM::S1::LayerA', 'T::AM::S1::LayerB' ],
  );
  $schema_a->storage($storage_a);
  $schema_b->storage($storage_b);

  my $async_a = $storage_a->async;
  my $async_b = $storage_b->async;
  is ref($storage_a), ref($storage_b),
    'independent sync storages have the same class shape';
  isnt Scalar::Util::refaddr($storage_a), Scalar::Util::refaddr($storage_b),
    'sync owners are distinct objects';
  is ref($async_a), ref($async_b),
    'independent async backends have the same synthesized class';
  isnt Scalar::Util::refaddr($async_a), Scalar::Util::refaddr($async_b),
    'async backends are distinct objects';
  is Scalar::Util::refaddr($async_a->_owner_storage),
    Scalar::Util::refaddr($storage_a),
    'composed async backend A points at its concrete sync owner';
  is Scalar::Util::refaddr($async_b->_owner_storage),
    Scalar::Util::refaddr($storage_b),
    'composed async backend B points at its concrete sync owner';

  my $ctx_class = $async_a->_txn_context_class;
  my $ctx_a = $ctx_class->new(storage => $async_a, txn_conn => 'CONN_A');
  my $ctx_b = $ctx_class->new(storage => $async_b, txn_conn => 'CONN_B');

  my $bound;
  lives_ok {
    $bound = $schema_a->resultset('Artist')->with_context($ctx_a);
  } 'same-owner context is accepted on composed storage';
  is $bound ? Scalar::Util::refaddr($bound->_async_context) : undef,
    Scalar::Util::refaddr($ctx_a),
    'same composed context is carried unchanged';
  throws_ok {
    $schema_a->resultset('Artist')->with_context($ctx_b);
  } qr/does not belong to this storage generation/,
    'identically composed foreign context is rejected';
}

# ===========================================================================
# Scenario 2: async_layer_class($mode) returns a package -> that package is
# used (the convention ::Async sibling does not even exist here).
# ===========================================================================
{
  package T::AM::S2::Storage;         use base 'DBIO::Test::Storage'; use mro 'c3';
  package T::AM::S2::Transport;       use base 'T::AM::RecordingTransport'; use mro 'c3';

  package T::AM::S2::Layer;
  sub async_layer_class { my ($class, $mode) = @_; return 'T::AM::S2::PickedAsync' }
  package T::AM::S2::PickedAsync;     sub picked { 1 }
}
T::AM::S2::Storage->register_async_mode( ram => 'T::AM::S2::Transport' );

{
  my ($storage, $schema) = build_storage(
    storage_class => 'T::AM::S2::Storage',
    mode          => 'ram',
    layers        => [ 'T::AM::S2::Layer' ],
  );
  my $async = $storage->async;
  isa_ok $async, 'T::AM::S2::PickedAsync',
    'async_layer_class($mode) return value was used as the async layer';
  is_deeply [ DBIO::Storage::Composed->layers_of(ref $async) ],
    [ 'T::AM::S2::PickedAsync' ], 'the picked async layer, not a convention sibling';
}

# ===========================================================================
# Scenario 3: async_layer_class($mode) is DEFINED and returns undef -> the
# STATED sync-only opt-out (ADR 0032 amendment 2026-09-25, karr k159, form A').
# The layer is skipped: no async layer is composed and no convention sibling
# is even probed.
#
# This REPLACES the pre-k159 claim of this scenario ("undef falls back to the
# ::Async convention"). undef used to mean "use the convention", which left no
# way to SAY "deliberately sync-only"; the maintainer decision of 2026-09-24
# moved "use the convention" to the method not being defined at all.
# ===========================================================================
{
  package T::AM::S3::Storage;         use base 'DBIO::Test::Storage'; use mro 'c3';
  package T::AM::S3::Transport;       use base 'T::AM::RecordingTransport'; use mro 'c3';

  # 3a: a convention sibling EXISTS in memory. Were the declaration ignored,
  # convention resolution would find it and compose it in.
  package T::AM::S3::Layer;
  sub async_layer_class { undef }     # stated: deliberately sync-only
  package T::AM::S3::Layer::Async;    sub via_convention { 1 }

  # 3b: no sibling in memory; an @INC hook below records any attempt to
  # require it from disk. Were the declaration ignored, the convention probe
  # would try to load it.
  package T::AM::S3::Quiet;
  sub async_layer_class { return }    # bare return: undef in scalar context

  # 3c: a silent neighbour WITH a sibling, so the backend still carries
  # something -- the opt-out must skip only the declaring layer.
  package T::AM::S3::Other;           sub other { 1 }
  package T::AM::S3::Other::Async;    sub other_async { 1 }

  # 3d: per-mode granularity -- sync-only under one mode, a mirror under another.
  package T::AM::S3::PerMode;
  sub async_layer_class {
    my ($class, $mode) = @_;
    return $mode eq 'ram' ? undef : 'T::AM::S3::PerModeAsync';
  }
  package T::AM::S3::PerModeAsync;    sub per_mode_async { 1 }
}
T::AM::S3::Storage->register_async_mode( ram  => 'T::AM::S3::Transport' );
T::AM::S3::Storage->register_async_mode( ram2 => 'T::AM::S3::Transport' );

{
  my ($storage, $schema) = build_storage(
    storage_class => 'T::AM::S3::Storage',
    mode          => 'ram',
    layers        => [ 'T::AM::S3::Layer', 'T::AM::S3::Other' ],
  );
  my $async = $storage->async;
  isa_ok $async, 'T::AM::S3::Transport',
    'a stated sync-only layer does not stop the transport from resolving';
  ok !$async->isa('T::AM::S3::Layer::Async'),
    'async_layer_class returning undef is a stated opt-out: the existing '
  . '::Async sibling is NOT composed';
  ok !$async->can('via_convention'),
    'none of the ignored sibling\'s methods reach the async backend';
  is_deeply [ DBIO::Storage::Composed->layers_of(ref $async) ],
    [ 'T::AM::S3::Other::Async' ],
    'only the silent neighbour\'s convention mirror is composed';
}

{
  my @attempts;
  local @INC = (
    sub {
      my (undef, $file) = @_;
      push @attempts, $file if $file =~ m{^T/AM/S3/};
      return;
    },
    @INC,
  );
  my ($storage, $schema) = build_storage(
    storage_class => 'T::AM::S3::Storage',
    mode          => 'ram',
    layers        => [ 'T::AM::S3::Quiet' ],
  );
  my $async = $storage->async;
  is_deeply \@attempts, [],
    'a stated sync-only layer triggers no load attempt of T::AM::S3::Quiet::Async';
  is_deeply [ DBIO::Storage::Composed->layers_of(ref $async) ], [],
    'and no async layer is composed for it';
}

{
  my ($storage, $schema) = build_storage(
    storage_class => 'T::AM::S3::Storage',
    mode          => 'ram',
    layers        => [ 'T::AM::S3::PerMode' ],
  );
  my $async = $storage->async;
  ok !$async->isa('T::AM::S3::PerModeAsync'),
    'per-mode opt-out: sync-only under the mode that answers undef';

  my ($storage2, $schema2) = build_storage(
    storage_class => 'T::AM::S3::Storage',
    mode          => 'ram2',
    layers        => [ 'T::AM::S3::PerMode' ],
  );
  isa_ok $storage2->async, 'T::AM::S3::PerModeAsync',
    'per-mode opt-out: the same layer mirrors under a mode that names a class';
}

# ===========================================================================
# Scenario 4: transport capabilities gate. A layer requiring 'x' croaks over a
# transport without it, and composes over a transport that declares it.
# ===========================================================================
{
  package T::AM::S4::Plain::Storage;    use base 'DBIO::Test::Storage'; use mro 'c3';
  package T::AM::S4::PlainTransport;    use base 'T::AM::RecordingTransport'; use mro 'c3';
  # transport_capabilities defaults to () -- provides nothing.

  package T::AM::S4::Cap::Storage;      use base 'DBIO::Test::Storage'; use mro 'c3';
  package T::AM::S4::CapTransport;      use base 'T::AM::RecordingTransport'; use mro 'c3';
  sub transport_capabilities { ('x') }

  package T::AM::S4::Layer;
  package T::AM::S4::Layer::Async;
  sub required_transport_capabilities { ('x') }
}
T::AM::S4::Plain::Storage->register_async_mode( ram => 'T::AM::S4::PlainTransport' );
T::AM::S4::Cap::Storage->register_async_mode(   ram => 'T::AM::S4::CapTransport' );

{
  my ($storage, $schema) = build_storage(
    storage_class => 'T::AM::S4::Plain::Storage',
    mode          => 'ram',
    layers        => [ 'T::AM::S4::Layer' ],
  );
  eval { $storage->async };
  my $err = $@;
  ok $err, 'a required capability the transport lacks croaks';
  like $err, qr/T::AM::S4::Layer::Async/, 'the croak names the async layer';
  like $err, qr/\bx\b/,                   'the croak names the missing capability';
  like $err, qr/T::AM::S4::PlainTransport/, 'the croak names the transport';
  like $err, qr/choose another async mode/, 'the croak carries the upgrade/choose hint';
}

{
  my ($storage, $schema) = build_storage(
    storage_class => 'T::AM::S4::Cap::Storage',
    mode          => 'ram',
    layers        => [ 'T::AM::S4::Layer' ],
  );
  my $async = $storage->async;
  isa_ok $async, 'T::AM::S4::Layer::Async',
    'the layer composes over a transport that declares the required capability';
  isa_ok $async, 'T::AM::S4::CapTransport', 'composed over the capable transport';
}

# ===========================================================================
# Scenario 5: a layer that does NOT define async_layer_class AND has no
# ::Async sibling -> REFUSAL (karr k159 step 3, ADR 0032 amendment 2026-09-25).
# Before step 3 such a layer was skipped silently, so a typo in a mirror's
# package name was indistinguishable from a deliberately sync-only extension.
# The refusal must name the layer and show both ways out.
# ===========================================================================
{
  package T::AM::S5::Storage;         use base 'DBIO::Test::Storage'; use mro 'c3';
  package T::AM::S5::Transport;       use base 'T::AM::RecordingTransport'; use mro 'c3';

  package T::AM::S5::Silent;          sub silent { 1 }    # no decl, no sibling
  package T::AM::S5::Declared;        sub declared { 1 }
  sub async_layer_class { undef }                         # stated sync-only
  package T::AM::S5::Mirrored;        sub mirrored { 1 }  # no decl, WITH sibling
  package T::AM::S5::Mirrored::Async; sub mirrored_async { 1 }
}
T::AM::S5::Storage->register_async_mode( ram => 'T::AM::S5::Transport' );

{
  my ($storage, $schema) = build_storage(
    storage_class => 'T::AM::S5::Storage',
    mode          => 'ram',
    layers        => [ 'T::AM::S5::Mirrored', 'T::AM::S5::Silent' ],
  );
  my $async = eval { $storage->async };
  my $err   = $@;
  ok !defined $async, 'a silent layer without an ::Async sibling yields no backend';
  isa_ok $err, 'DBIO::Exception', 'the refusal is a DBIO::Exception';
  like "$err", qr/storage layer 'T::AM::S5::Silent'/,
    'the refusal names the offending layer';
  like "$err", qr/'ram'/, '... and the async mode';
  like "$err", qr/T::AM::S5::Silent::Async/,
    '... and the convention sibling it looked for';
  like "$err", qr/sub async_layer_class \{ undef \}/,
    'way out 1: declare the layer sync-only';
  like "$err", qr/ship the async mirror as 'T::AM::S5::Silent::Async'/,
    'way out 2: ship the ::Async sibling';
  like "$err", qr/ADR 0032/, 'the refusal points at ADR 0032';
  unlike "$err", qr/T::AM::S5::Mirrored/,
    'the well-formed neighbour is not blamed';
}

{
  my ($storage, $schema) = build_storage(
    storage_class => 'T::AM::S5::Storage',
    mode          => 'ram',
    layers        => [ 'T::AM::S5::Declared', 'T::AM::S5::Mirrored' ],
  );
  my $async;
  lives_ok { $async = $storage->async }
    'a declared sync-only layer next to a mirrored one does not croak';
  ok !$async->can('declared'), 'the declared sync-only layer is not composed';
  isa_ok $async, 'T::AM::S5::Mirrored::Async',
    'the convention sibling is still mirrored';
  is_deeply [ DBIO::Storage::Composed->layers_of(ref $async) ],
    [ 'T::AM::S5::Mirrored::Async' ],
    'exactly the convention mirror composed over the transport';
}

done_testing;
