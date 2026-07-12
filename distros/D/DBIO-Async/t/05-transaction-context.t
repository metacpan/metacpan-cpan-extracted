use strict;
use warnings;
use Test::More;

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use DBIO::Async::TransactionContext;

# Minimal mock storage and connection.
#
# The mock records, per executed query, WHICH execution seam it went
# through and WHICH connection it ran on. This is what lets the tests
# below catch the pinning bug: if a context CRUD call ever forwarded to
# the non-pinned _query_async (a fresh pool connection) instead of the
# pinned path, the recorded seam/conn would be wrong and the assertions
# would fail.
{
  package MockStorage5;
  sub new { bless { pool => MockPool5->new, _log => [] }, $_[0] }
  sub pool { $_[0]->{pool} }
  sub sql_maker { 'MockSQLMaker5' }
  sub _txn_conn_accessor { 'txn_conn' }

  # Non-pinned path: must NOT be reached by a TransactionContext.
  sub _query_async {
    my ($self, $sql, $bind) = @_;
    push @{ $self->{_log} }, { seam => 'pooled', conn => undef, sql => $sql };
    return Future->done([]);
  }
  # Pinned path: the only correct seam for in-txn CRUD. Returns the
  # result as a flat list of rows, matching the real _query_async_pinned
  # which does $f->done(@$rows).
  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{_log} }, { seam => 'pinned', conn => $conn, sql => $sql };
    return Future->done(['row']);
  }

  # Shared CRUD builder seam, mirroring the real storage: builds a label
  # for the op and runs it on the pinned connection. The select_single
  # first-row post-processing is exercised here so the context's reliance
  # on it is covered.
  sub _run_crud_pinned {
    my ($self, $op, $conn, @args) = @_;
    my $sql = "MOCK $op";
    my $f = $self->_query_async_pinned($conn, $sql, []);
    return $f unless $op eq 'select_single';
    return $f->then(sub { my @rows = @_; return @rows ? $rows[0] : undef });
  }
}
{
  package MockPool5;
  sub new { bless {}, $_[0] }
  sub release { }
}
{
  package MockConn5;
  sub new { bless {}, $_[0] }
}

my $storage = MockStorage5->new;
my $conn    = MockConn5->new;
my $ctx     = DBIO::Async::TransactionContext->new(
  storage  => $storage,
  txn_conn => $conn,
);

isa_ok $ctx, 'DBIO::Async::TransactionContext';

# in_txn is always true
ok $ctx->in_txn, 'in_txn returns true';

# txn_conn returns the pinned connection
is $ctx->txn_conn, $conn, 'txn_conn returns the connection';

# pool delegates to storage
is $ctx->pool, $storage->pool, 'pool delegates to underlying storage';

# _query_async forwards to the pinned execution path
my $f = $ctx->_query_async('SELECT 1', []);
isa_ok $f, 'Future';
is $storage->{_log}[-1]{seam}, 'pinned', '_query_async uses the pinned seam';
is $storage->{_log}[-1]{conn}, $conn, '_query_async runs on the pinned connection';

# --- The core assertion: CRUD through the context MUST hit the
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

ok( (!grep { !defined $_->{conn} || $_->{conn} != $conn } @{ $storage->{_log} }),
  'every context CRUD call ran on the pinned connection' );

# select_single still post-processes to the first row through the context
is_deeply $single, ['row'], 'select_single_async returns the first row';

# Sync wrappers run through the same pinned async path
$storage->{_log} = [];
$ctx->insert('artist', { name => 'sync' });
is $storage->{_log}[-1]{seam}, 'pinned', 'sync insert() also pins the connection';

done_testing;
