use strict;
use warnings;
use Test::More;

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use DBIO::PostgreSQL::EV::TransactionContext;
use DBIO::PostgreSQL::EV::Storage;

# Minimal mock storage and connection.
#
# The mock records, per executed query, WHICH execution seam it went
# through and WHICH connection it ran on. This is what lets the tests
# below catch the pinning bug: if a context CRUD call ever forwarded to
# the non-pinned _query_async (a fresh pool connection) instead of the
# pinned path, the recorded seam/conn would be wrong and the assertions
# would fail.
{
  package MockStorage27;
  sub new { bless { pool => MockPool27->new, _log => [], _owner_token => \(my $t) }, $_[0] }
  sub pool { $_[0]->{pool} }
  sub sql_maker { 'MockSQLMaker27' }

  # k196 ownership contract (adopted in k38): core's TransactionContext snapshots
  # the backend's owner token at construction and, on every pinned op, resolves
  # the backend's owner and has THAT owner prove ownership of the context
  # (_assert_context_active -> _owner_storage -> _assert_async_context_owner).
  # This mock is a SINGLE ownership domain: it is its own owner and accepts its
  # own contexts. The token is a stable per-object ref, identical on every call.
  # Ownership REJECTION is proven separately by t/28-context-ownership-mock.t;
  # this file's intent is PINNING, so an accepting owner is correct here and
  # weakens none of the pinned-seam / pinned-conn assertions below.
  sub _context_owner_token { $_[0]->{_owner_token} }
  sub _owner_storage       { $_[0] }
  sub _assert_async_context_owner { $_[1] }

  # Non-pinned path: must NOT be reached by a TransactionContext.
  sub _query_async {
    my ($self, $sql, $bind) = @_;
    push @{ $self->{_log} }, { seam => 'pooled', pg => undef, sql => $sql };
    return Future->done([]);
  }
  # Pinned path: the only correct seam for in-txn CRUD. Returns the
  # result as a flat list of rows, matching the real _query_async_pinned
  # which does $f->done(@$rows).
  sub _query_async_pinned {
    my ($self, $pg, $sql, $bind) = @_;
    push @{ $self->{_log} }, { seam => 'pinned', pg => $pg, sql => $sql };
    return Future->done(['row']);
  }

  # Shared CRUD builder seam, mirroring the real storage: builds a label
  # for the op and runs it on the pinned connection. The select_single
  # first-row post-processing is exercised here so the context's reliance
  # on it is covered.
  sub _run_crud_pinned {
    my ($self, $op, $pg, @args) = @_;
    my $sql = "MOCK $op";
    my $f = $self->_query_async_pinned($pg, $sql, []);
    return $f unless $op eq 'select_single';
    return $f->then(sub { my @rows = @_; return @rows ? $rows[0] : undef });
  }
}
{
  package MockPool27;
  sub new { bless {}, $_[0] }
  sub release { }
}
{
  package MockConn27;
  sub new { bless {}, $_[0] }
}

my $storage = MockStorage27->new;
my $pg      = MockConn27->new;
# karr k32: the constructor key moved from the driver-native 'pg' to core's
# 'txn_conn'. That is not cosmetics -- core's txn_do_async builds the context as
# $class->new(storage => ..., $accessor => $conn) with $accessor being
# _txn_conn_accessor, so the seam's value and this key are the same thing, and
# the constructor is now core's.
my $ctx     = DBIO::PostgreSQL::EV::TransactionContext->new(
  storage  => $storage,
  txn_conn => $pg,
);

isa_ok $ctx, 'DBIO::PostgreSQL::EV::TransactionContext';
isa_ok $ctx, 'DBIO::Storage::Async::TransactionContext';

# The old key is GONE, not merely unused: core's constructor dies without
# txn_conn. Pinned so a silent revival of the local constructor is caught.
{
  my $died = ! eval {
    DBIO::PostgreSQL::EV::TransactionContext->new(storage => $storage, pg => $pg);
    1;
  };
  ok $died, 'the pre-k32 constructor key pg is refused, not silently accepted';
}

# in_txn is always true
ok $ctx->in_txn, 'in_txn returns true';

# txn_pg returns the pinned connection. This claim is PRESERVED across k32 --
# it is the one method this class still defines, and it is load bearing:
# t/21-deploy-async-live.t:271 drives _execute_ddl_async through it.
is $ctx->txn_pg, $pg, 'txn_pg returns the connection';

# ...and it is an alias for the inherited core accessor, not a second store.
is $ctx->txn_conn, $pg, 'the inherited txn_conn returns the same connection';
is $ctx->txn_pg, $ctx->txn_conn, 'txn_pg and txn_conn answer the same handle';

# The seam that names the constructor key and the key actually used must agree;
# they are one fact, asserted from both sides.
my $accessor = DBIO::PostgreSQL::EV::Storage->_txn_conn_accessor;
is $accessor, 'txn_conn',
  '_txn_conn_accessor names the key this context is built with';

# ADR 0045: inherited for free by becoming a subclass. A context-bound
# ResultSet/Row consults this before routing an *_async op onto the context.
ok $ctx->_context_active, '_context_active is true on a live context (ADR 0045)';
$ctx->_invalidate;
ok !$ctx->_context_active, '_context_active is false after _invalidate';
$ctx->{_invalidated} = 0;

# pool delegates to storage
is $ctx->pool, $storage->pool, 'pool delegates to underlying storage';

# _query_async forwards to the pinned execution path
my $f = $ctx->_query_async('SELECT 1', []);
isa_ok $f, 'Future';
is $storage->{_log}[-1]{seam}, 'pinned', '_query_async uses the pinned seam';
is $storage->{_log}[-1]{pg}, $pg, '_query_async runs on the pinned connection';

# --- The core of the ticket: CRUD through the context MUST hit the
# pinned connection, never a fresh pooled one. ---

$storage->{_log} = [];

$ctx->select_async('artist', ['*'], {})->get;
$ctx->insert_async('artist', { name => 'x' })->get;
$ctx->update_async('artist', { name => 'y' }, { id => 1 })->get;
$ctx->delete_async('artist', { id => 1 })->get;
my $single = $ctx->select_single_async('artist', ['*'], { id => 1 })->get;

is scalar(@{ $storage->{_log} }), 5, 'all five CRUD calls executed';

ok( (!grep { $_->{seam} ne 'pinned' } @{ $storage->{_log} }),
  'every context CRUD call ran on the pinned seam (not the pooled _query_async)' );

ok( (!grep { !defined $_->{pg} || $_->{pg} != $pg } @{ $storage->{_log} }),
  'every context CRUD call ran on the pinned connection' );

# select_single still post-processes to the first row through the context
is_deeply $single, ['row'], 'select_single_async returns the first row';

# Sync wrappers run through the same pinned async path
$storage->{_log} = [];
$ctx->insert('artist', { name => 'sync' });
is $storage->{_log}[-1]{seam}, 'pinned', 'sync insert() also pins the connection';

done_testing;
