# ABSTRACT: karr #70 WP2/WP3 -- async mirror composition, capabilities, '?' seam contract
use strict;
use warnings;

use Test::More;

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use DBIO::Test;
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
  sub future_class     { 'Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _transform_sql   { $_[1] }        # identity: wire speaks '?'
  sub _post_insert_sql { '' }
  sub _query_async     { push @RECORDED, $_[1]; return Future->done }
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
# WITHOUT -> the backend is composed with exactly the one async layer.
# ===========================================================================
{
  package T::AM::S1::Storage;         use base 'DBIO::Test::Storage'; use mro 'c3';
  package T::AM::S1::Storage::Async;  use base 'T::AM::RecordingTransport'; use mro 'c3';

  package T::AM::S1::LayerA;          sub layer_a { 'a' }
  package T::AM::S1::LayerA::Async;   sub async_a { 'aa' }   # the async mirror
  package T::AM::S1::LayerB;          sub layer_b { 'b' }    # NO ::Async sibling
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
# Scenario 3: async_layer_class($mode) returns undef -> convention fallback.
# ===========================================================================
{
  package T::AM::S3::Storage;         use base 'DBIO::Test::Storage'; use mro 'c3';
  package T::AM::S3::Transport;       use base 'T::AM::RecordingTransport'; use mro 'c3';

  package T::AM::S3::Layer;
  sub async_layer_class { undef }     # explicitly defer to convention
  package T::AM::S3::Layer::Async;    sub via_convention { 1 }
}
T::AM::S3::Storage->register_async_mode( ram => 'T::AM::S3::Transport' );

{
  my ($storage, $schema) = build_storage(
    storage_class => 'T::AM::S3::Storage',
    mode          => 'ram',
    layers        => [ 'T::AM::S3::Layer' ],
  );
  my $async = $storage->async;
  isa_ok $async, 'T::AM::S3::Layer::Async',
    'async_layer_class returning undef fell back to the ::Async convention';
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

done_testing;
