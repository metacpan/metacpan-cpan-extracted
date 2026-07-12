use strict;
use warnings;
use Test::More;

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use DBIO::Async::Pool;
use DBIO::Async::Storage;

# OFFLINE unit test for the pool waiter/queue mechanics inherited from
# DBIO::Storage::PoolBase, exercised through DBIO::Async::Pool.
# Ported from dbio-postgresql-async t/pool-future-queue.t.

# --- FakeConn: minimal connection that reports as always ready ---

{
  package FakeConn6;
  sub new { bless { id => $_[1] }, $_[0] }
}

# --- TestStorage: provides seam hooks with ready connections ---

{
  package TestStorage6;
  use base 'DBIO::Async::Storage';

  sub sql_maker_class         { 'DBIO::SQLMaker' }
  sub _transform_sql          { $_[1] }
  sub _post_insert_sql        { '' }
  sub _normalize_conninfo     { $_[1] }
  sub _create_pool_connection { my $s = shift; FakeConn6->new(++$s->{_next_id}) }
  sub _shutdown_pool_connection { }
  sub _conn_ready             { 1 }
  sub _txn_context_class      { 'DBIO::Async::TransactionContext' }
  sub _txn_conn_accessor      { 'txn_conn' }
  sub _pipeline_enter         { }
  sub _pipeline_sync          { Future->done }
  sub _pipeline_exit          { }
}

my $storage = TestStorage6->new(undef);
$storage->{_next_id} = 0;
$storage->connect_info([{ host => 'localhost', pool_size => 1 }]);

my $pool = $storage->pool;

# First acquire: returns an immediately-resolved Future
my $f1 = $pool->acquire;
isa_ok $f1, 'Future', 'acquire returns a Future';
ok $f1->is_ready, 'first acquire resolves immediately';
my $conn1 = $f1->get;
isa_ok $conn1, 'FakeConn6', 'resolved to connection object';

# Second acquire with pool full: returns pending Future
my $f2 = $pool->acquire;
isa_ok $f2, 'Future', 'second acquire returns a Future';
ok !$f2->is_ready, 'second acquire is pending (pool full)';

# Release resolves the waiter
$pool->release($conn1);
ok $f2->is_ready, 'release resolves the pending Future';
my $conn2 = $f2->get;
isa_ok $conn2, 'FakeConn6', 'resolved to a connection';

done_testing;
