use strict;
use warnings;
use Test::More;
use Test::Exception;

use Scalar::Util ();
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::DBI;
use DBIO::Storage::Async;

# karr k204 / ADR 0051: a real async backend used as a PRIMARY storage --
# constructed directly at the driver level with NO embedding sync storage, the
# way the native EV backends are (DBIO::PostgreSQL::EV::Storage->new(undef) +
# connect_info, exactly as dbio-postgresql-ev's t/13-cold-pool-live.t and
# t/14-txn-live.t do) -- must be able to prepare a SELECT and prove async
# context ownership WITHOUT anyone wiring _owner_storage.
#
# WHY this is the missing coverage: every existing offline async test wires the
# owner by hand (t/test/15_async_orchestration.t new_backend:
# $backend->_owner_storage($owner); $owner->_async_context_owner_token(...)),
# which is exactly what masked the bug -- the embedded connect path
# (DBIO::Storage::DBI::_async_storage) sets the owner, the standalone/primary
# path never did. INSERT needs no owner (it does not route through
# _select_args), so it stayed green; the first SELECT and the first txn context
# assertion died live against a real DB. This test drives the standalone wiring
# path through a fully synchronous fake transport so the gap is caught offline.

# --- A fake pool: acquire hands out one fake connection in a ready Future. ----
{
  package Test::StandalonePool;
  sub new { bless { released => [] }, shift }
  sub future_class { 'DBIO::Test::Future' }
  sub acquire     { $_[0]->future_class->done('CONN') }
  sub acquire_txn { $_[0]->future_class->done('CONN') }
  sub release     { push @{ $_[0]{released} }, $_[1]; 1 }
  sub available   { 1 }
  sub shutdown    { }
}

# --- A concrete DBIO::Storage::Async overriding ONLY the transport seams. -----
# It captures every emitted statement and resolves each query immediately.
{
  package Test::StandaloneBackend;
  use base 'DBIO::Storage::Async';

  sub new {
    my ($class, $schema) = @_;
    my $self = $class->SUPER::new($schema);
    $self->{captured}  = [];
    $self->{next_rows} = [];
    return $self;
  }

  sub future_class     { 'DBIO::Test::Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { ' RETURNING *' }

  sub pool { $_[0]{pool} ||= Test::StandalonePool->new }

  sub _seam_result {
    my ($self, $sql, $bind) = @_;
    return $self->future_class->done(@{ $self->{next_rows} || [] });
  }
  sub _query_async {
    my ($self, $sql, $bind) = @_;
    push @{ $self->{captured} }, { sql => $sql, bind => $bind, pinned => 0 };
    return $self->_seam_result($sql, $bind);
  }
  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{captured} }, { sql => $sql, bind => $bind, pinned => 1, conn => $conn };
    return $self->_seam_result($sql, $bind);
  }
  sub _last_sql { $_[0]{captured}[-1]{sql} }
}

# A standalone/primary backend: no schema, no embedding sync storage, and --
# critically -- NOBODY calls $backend->_owner_storage($owner). This mirrors
# DBIO::PostgreSQL::EV::Storage->new(undef); $storage->connect_info([...]).
sub standalone_backend {
  my $backend = Test::StandaloneBackend->new(undef);
  $backend->connect_info([ { host => 'localhost', dbname => 'test' }, {} ]);
  return $backend;
}

# ---------------------------------------------------------------------------
# 1. No owner is wired -- the pre-fix precondition the live failure hit.
# ---------------------------------------------------------------------------
{
  my $backend = standalone_backend();
  is $backend->_owner_storage, undef,
    'standalone/primary backend has NO externally-wired _owner_storage (the live shape)';
}

# ---------------------------------------------------------------------------
# 2. A standalone backend prepares and runs an async SELECT.
#    Pre-fix: throws "async SELECT requires its owning sync storage".
# ---------------------------------------------------------------------------
{
  my $backend = standalone_backend();
  $backend->{next_rows} = [ [ 1, 'Miles Davis' ], [ 2, 'John Coltrane' ] ];

  my @rows;
  lives_ok {
    @rows = $backend->select_async('artist', [ 'artistid', 'name' ], { name => { -like => '%' } })->get;
  } 'standalone select_async does not die for lack of an owning sync storage (karr k204)';

  is_deeply \@rows, [ [ 1, 'Miles Davis' ], [ 2, 'John Coltrane' ] ],
    'standalone select_async resolves with the raw result rows';

  like $backend->_last_sql, qr/^SELECT\b.*\bFROM\b.*"artist"/,
    'standalone select_async emitted real maker SQL for the artist table';
}

# ---------------------------------------------------------------------------
# 3. The effective owner is a real DBIO::Storage::DBI routing through
#    _select_args (ADR 0046 parity), sharing THIS backend's sql_maker so the
#    prepared SQL is byte-identical to the async path's own maker.
# ---------------------------------------------------------------------------
{
  my $backend = standalone_backend();
  my $owner   = $backend->_effective_owner_storage;

  isa_ok $owner, 'DBIO::Storage::DBI',
    'effective owner of an unowned backend is a real sync DBIO::Storage::DBI';
  ok $owner->can('_select_args'),
    'effective owner can _select_args -- the seam _prepare_select_args_async needs';
  is Scalar::Util::refaddr($owner->sql_maker), Scalar::Util::refaddr($backend->sql_maker),
    'self-provisioned owner shares the backend sql_maker (dialect parity, ADR 0046)';

  # The args _prepare_select_args_async hands the async maker must equal what
  # the owner's own _select_args would emit for the same query -- the mock
  # cursor invariant (karr core k55 / ADR 0046) applied to the async path.
  my @via_backend = $backend->_prepare_select_args_async(
    'artist', [ 'artistid', 'name' ], { name => 'x' }, {},
  );
  my ($sql_backend, @bind_backend) = $backend->sql_maker->select(@via_backend);

  my @via_owner = $owner->_select_args('artist', [ 'artistid', 'name' ], { name => 'x' }, {});
  shift @via_owner;   # drop the leading 'select' op name
  my ($sql_owner, @bind_owner) = $owner->sql_maker->select(@via_owner);

  is $sql_backend, $sql_owner,
    'standalone async SELECT SQL equals the sync _select_args SQL (parity)';
  is_deeply \@bind_backend, \@bind_owner,
    'standalone async SELECT bind equals the sync _select_args bind (parity)';
}

# ---------------------------------------------------------------------------
# 4. txn_do_async on a standalone backend: context ownership is provable, and
#    CRUD inside the callback runs on the pinned connection.
#    Pre-fix: throws "async context ownership cannot be proven".
# ---------------------------------------------------------------------------
{
  my $backend = standalone_backend();
  $backend->{next_rows} = [ { name => 'commit-me' } ];

  my @result;
  lives_ok {
    @result = $backend->txn_do_async(sub {
      my ($txn) = @_;
      return $txn->insert_async('artist', { name => 'commit-me' });
    })->get;
  } 'standalone txn_do_async proves context ownership without a wired owner (karr k204)';

  is ref($result[0]), 'HASH',
    'insert_async inside the standalone txn resolved with a returned-columns HASHREF';

  # BEGIN + INSERT + COMMIT all ran on the same pinned connection.
  my @pinned = grep { $_->{pinned} } @{ $backend->{captured} };
  ok scalar(@pinned) >= 3, 'txn statements ran on the pinned connection';
  like $pinned[0]{sql}, qr/^BEGIN$/, 'first pinned statement is BEGIN';
}

# ---------------------------------------------------------------------------
# 5. A SELECT inside a standalone txn also prepares its args through the
#    effective owner (the other half of the live failure, t/14 line 125).
# ---------------------------------------------------------------------------
{
  my $backend = standalone_backend();
  $backend->{next_rows} = [ [ 7, 'persisted' ] ];

  my @rows;
  lives_ok {
    @rows = $backend->txn_do_async(sub {
      my ($txn) = @_;
      return $txn->select_async('artist', [ 'artistid', 'name' ], { name => 'persisted' });
    })->get;
  } 'standalone txn select_async prepares args through the effective owner (karr k204)';

  is_deeply \@rows, [ [ 7, 'persisted' ] ],
    'standalone txn select_async resolves with the pinned-connection rows';
}

# ---------------------------------------------------------------------------
# 6. Backward compatibility (karr k204 addendum): a bare driver MOCK that plays
#    the backend role for a context and fulfils only the OLDER _owner_storage
#    contract -- never gaining _effective_owner_storage -- must still work. Core
#    call-sites resolve through DBIO::Storage::Async::_effective_owner_of, which
#    falls back to _owner_storage. This mirrors dbio-postgresql-ev's
#    MockStorage27 (t/transaction-context.t), which sets _owner_storage to
#    itself and never subclasses DBIO::Storage::Async.
# ---------------------------------------------------------------------------
{
  package Test::BareContextStorage;
  # NOT a DBIO::Storage::Async subclass: no _effective_owner_storage anywhere.
  sub new { bless { token => \(my $o), asserted => 0 }, shift }
  sub _context_owner_token   { $_[0]{token} }
  sub _owner_storage         { $_[0] }                 # its own owner, as MockStorage27
  sub _assert_async_context_owner { $_[0]{asserted}++; return $_[1] }
  sub pool                   { undef }
}
{
  my $mock = Test::BareContextStorage->new;

  ok !$mock->can('_effective_owner_storage'),
    'bare mock has no _effective_owner_storage (the older contract only)';

  my $resolved = DBIO::Storage::Async::_effective_owner_of($mock);
  is Scalar::Util::refaddr($resolved), Scalar::Util::refaddr($mock),
    '_effective_owner_of falls back to _owner_storage for a bare mock (no crash)';

  # The context path must resolve ownership through the helper without demanding
  # _effective_owner_storage on the mock backend.
  my $ctx = DBIO::Storage::Async::TransactionContext->new(
    storage => $mock, txn_conn => 'CONN',
  );
  lives_ok { $ctx->_assert_context_active }
    'TransactionContext ownership check works over a bare _owner_storage-only mock (karr k204 backward-compat)';
  ok $mock->{asserted},
    'ownership was proven against the mock owner, not skipped';
}

done_testing;
