use strict;
use warnings;
use Test::More;
use Test::Exception;

use Scalar::Util ();
use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::Future::Immediate;
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::Async::TransactionContext;

# karr k207 / ADR 0055: the STORAGE-LEVEL txn_do_async contract is backend-
# independent along its callback INPUT and its RETURN adoption, so the
# documented portable pattern
#
#     sub { my ($ctx) = @_; $ctx->*_async(...) }
#
# is substitutable between the `immediate` mode and a real DBIO::Storage::Async
# backend. Two axes the k201 audit (ADR 0053) confirmed incompatible:
#
#   1. Callback signature -- a real backend calls $coderef->($ctx, @args): the
#      first argument is a context whose *_async methods run the op inside the
#      transaction. immediate used to run the sync txn_do($coderef, @args),
#      calling $coderef->(@args) -- NO context, so my ($ctx) = @_ took the first
#      caller arg (or undef), and $ctx->insert_async died "on an undefined
#      value".
#   2. Returned-Future adoption -- a real backend adopts a Future the coderef
#      returns (resolves with its VALUE, commits on success / rolls back on
#      failure). immediate used to wrap the returned Future as the resolved
#      value, so ->get handed back the Future OBJECT.
#
# This is offline mock-only: the real backend is a fully-synchronous
# DBIO::Storage::Async transport (no event loop, no database), the same
# orchestration harness t/test/15_async_orchestration.t drives. It is the
# oracle; immediate is compared against it. The assertions sample the PROPERTY
# (substitutability), not today's divergence.

# --- A fake, fully-synchronous pool ----------------------------------------
{
  package Test::SyncPool;
  sub new { bless { released => [] }, shift }
  sub future_class { 'DBIO::Test::Future' }
  sub acquire     { $_[0]->future_class->done('CONN') }
  sub acquire_txn { $_[0]->future_class->done('CONN') }
  sub release     { push @{ $_[0]{released} }, $_[1]; 1 }
  sub available   { 1 }
  sub shutdown    { }
}

# --- The real async transport backend (overrides only the seam hooks) -------
{
  package Test::SyncBackend;
  use base 'DBIO::Storage::Async';

  sub new {
    my ($class, $schema) = @_;
    my $self = $class->SUPER::new($schema);
    $self->{captured}  = [];
    $self->{next_rows} = [];
    return $self;
  }

  sub future_class    { 'DBIO::Test::Future' }
  sub sql_maker_class { 'DBIO::SQLMaker' }
  sub _sql_maker_args { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { ' RETURNING *' }

  sub pool { $_[0]->{pool} ||= Test::SyncPool->new }

  sub _seam_result {
    my ($self, $sql, $bind) = @_;
    return $self->future_class->done(@{ $self->{next_rows} || [] });
  }

  sub _query_async {
    my ($self, $sql, $bind) = @_;
    push @{ $self->{captured} }, $sql;
    return $self->_seam_result($sql, $bind);
  }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{captured} }, $sql;
    return $self->_seam_result($sql, $bind);
  }
}

# Wire the backend to an owning sync storage + shared context-owner token, so
# the generic TransactionContext's ownership assertions succeed (as in
# t/test/15_async_orchestration.t's new_backend). Returns ($backend, $schema);
# the schema is returned so the caller keeps it alive (the backend weakens it).
sub new_real_backend {
  my $schema  = DBIO::Test->init_schema;
  my $backend = Test::SyncBackend->new($schema);
  my $owner   = $schema->storage;
  $backend->_owner_storage($owner);
  $owner->_async_context_owner_token($backend->_context_owner_token);
  return ($backend, $schema);
}

# An immediate-mode mock storage (DBIO::Test::Storage defaults to 'immediate').
sub new_immediate_storage {
  my $schema = DBIO::Test->init_schema;
  is $schema->storage->_async_mode, 'immediate',
    'mock storage is in immediate async mode';
  return ($schema->storage, $schema);
}

sub artist_select_args {
  my ($schema) = @_;
  my $a = $schema->resultset('Artist')
                 ->search(undef, { order_by => 'me.artistid' })
                 ->_resolved_attrs;
  return ($a->{from}, $a->{select}, $a->{where}, $a);
}

my @ARTIST_ROWS = (
  [ 1, 'Miles Davis',   13, undef ],
  [ 2, 'John Coltrane', 13, undef ],
);

# ---------------------------------------------------------------------------
# Axis 1 -- callback signature: the coderef's first argument is a usable
# context (responds to *_async), and the caller's extra args follow it,
# identically across a real backend and immediate.
# ---------------------------------------------------------------------------
sub capture_signature {
  my ($storage, @extra_args) = @_;
  my %seen;
  my $coderef = sub {
    my ($ctx, @extra) = @_;
    $seen{ctx_defined}   = defined($ctx) ? 1 : 0;
    $seen{ctx_can_crud}  =
      ( Scalar::Util::blessed($ctx)
        && $ctx->can('insert_async')
        && $ctx->can('select_async') ) ? 1 : 0;
    $seen{extra}         = [ @extra ];
    return 'ok';   # plain value -> commit, resolve with 'ok'
  };
  my $result = $storage->txn_do_async($coderef, @extra_args)->get;
  $seen{result} = $result;
  return \%seen;
}

{
  my ($real) = new_real_backend();
  my ($imm)  = new_immediate_storage();

  my $real_sig = capture_signature($real, 'arg1', 'arg2');
  my $imm_sig  = capture_signature($imm,  'arg1', 'arg2');

  # The property: identical callback signature across the two backends.
  is_deeply $imm_sig, $real_sig,
    'immediate hands the coderef the same signature as a real backend';

  # And spell it out, so the equality above cannot be satisfied by two matching
  # WRONG signatures (e.g. both handing undef, or both dropping an arg).
  is $imm_sig->{ctx_defined}, 1,
    'immediate coderef receives a defined context as its first argument';
  is $imm_sig->{ctx_can_crud}, 1,
    'the immediate context responds to insert_async / select_async';
  is_deeply $imm_sig->{extra}, [ 'arg1', 'arg2' ],
    'the caller-supplied args follow the context, none consumed by it';
  is $imm_sig->{result}, 'ok',
    'a plain-value coderef commits and resolves with that value';
}

# ---------------------------------------------------------------------------
# Axis 2 -- returned-Future adoption: a Future the coderef returns is adopted,
# so txn_do_async resolves with the Future's VALUE(S), not the Future object.
# ---------------------------------------------------------------------------
{
  my ($real) = new_real_backend();
  my ($imm)  = new_immediate_storage();

  # Single-value return.
  for my $case (
    [ real => $real ],
    [ immediate => $imm ],
  ) {
    my ($label, $storage) = @$case;
    my $fc = $storage->future_class;
    my $resolved = $storage->txn_do_async(sub {
      return $fc->done('inner-value');
    })->get;

    is $resolved, 'inner-value',
      "$label: a returned Future is adopted -- resolves with its value";
    ok !( Scalar::Util::blessed($resolved) && $resolved->can('get') ),
      "$label: the resolved payload is the value, not a Future object";
  }

  # Multi-value return: all resolved values survive the adoption, in order.
  my ($real2) = new_real_backend();
  my ($imm2)  = new_immediate_storage();

  my @real_multi = $real2->txn_do_async(sub {
    return $real2->future_class->done('a', 'b', 'c');
  })->get;
  my @imm_multi = $imm2->txn_do_async(sub {
    return $imm2->future_class->done('a', 'b', 'c');
  })->get;

  is_deeply \@imm_multi, \@real_multi,
    'immediate adopts a multi-value returned Future exactly as a real backend';
  is_deeply \@imm_multi, [ 'a', 'b', 'c' ],
    'and preserves every resolved value in order';
}

# ---------------------------------------------------------------------------
# Axis 1 + 2 combined -- the exact documented portable pattern runs and
# resolves with the SAME rows across both modes. Under the old immediate this
# died: "Can't call method select_async on an undefined value".
# ---------------------------------------------------------------------------
{
  my ($real, $schema_real) = new_real_backend();
  $real->{next_rows} = [ @ARTIST_ROWS ];

  my ($imm, $schema_imm) = new_immediate_storage();
  $imm->mock_persistent(qr/FROM "artist"/i, [ @ARTIST_ROWS ]);

  my ($real_rows, $imm_rows);
  lives_ok {
    $real_rows = [ $real->txn_do_async(sub {
      my ($ctx) = @_;
      return $ctx->select_async(artist_select_args($schema_real));
    })->get ];
  } 'portable pattern runs under a real backend';

  lives_ok {
    $imm_rows = [ $imm->txn_do_async(sub {
      my ($ctx) = @_;
      return $ctx->select_async(artist_select_args($schema_imm));
    })->get ];
  } 'portable pattern runs under immediate (no "undefined value" death)';

  is_deeply $imm_rows, $real_rows,
    'the portable ctx->select_async pattern resolves identically across modes';
  is_deeply $imm_rows, [ @ARTIST_ROWS ],
    'and carries the expected raw result rows';
}

# ---------------------------------------------------------------------------
# Rollback parity -- a coderef that returns a FAILED Future rolls back and the
# outer transaction fails in BOTH modes (not commit-with-a-failed-Future-value).
# ---------------------------------------------------------------------------
{
  my ($real) = new_real_backend();
  my ($imm)  = new_immediate_storage();

  for my $case (
    [ real => $real ],
    [ immediate => $imm ],
  ) {
    my ($label, $storage) = @$case;
    my $fc = $storage->future_class;
    my $f = $storage->txn_do_async(sub {
      return $fc->fail("inner blew up\n");
    });
    ok $f->is_failed,
      "$label: a returned failed Future rolls back -- outer transaction fails";
  }
}

# And a coderef that throws fails in both modes (unchanged, guards regression).
{
  my ($real) = new_real_backend();
  my ($imm)  = new_immediate_storage();

  ok $real->txn_do_async(sub { die "boom\n" })->is_failed,
    'real backend: a thrown coderef fails the transaction';
  ok $imm->txn_do_async(sub { die "boom\n" })->is_failed,
    'immediate: a thrown coderef fails the transaction';
}

done_testing;
