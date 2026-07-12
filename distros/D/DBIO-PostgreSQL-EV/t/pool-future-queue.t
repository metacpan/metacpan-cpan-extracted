use strict;
use warnings;
use Test::More;

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use DBIO::PostgreSQL::EV::Pool;

# Subclass Pool to avoid real EV::Pg connections
{
  package MockConn;
  sub new { bless { id => $_[1] }, $_[0] }
  # acquire() now gates on connection readiness (karr #9, hoisted to core
  # PoolBase in karr #75). This test exercises the waiter/queue mechanics, not
  # readiness, so report the mock as already connected --
  # _connection_ready_future then resolves immediately and the queue
  # behaviour under test is unchanged.
  sub is_connected { 1 }
}

{
  package TestPool;
  use base 'DBIO::PostgreSQL::EV::Pool';
  # PoolBase._spawn_connection tracks the connection in _connections;
  # the subclass hook just builds one.
  sub _create_connection { my $s = shift; MockConn->new(++$s->{_next_id}) }
}

my $pool = TestPool->new(conninfo => 'fake', size => 1);
$pool->{_next_id} = 1;

# First acquire: returns an immediately-resolved Future
my $f1 = $pool->acquire;
isa_ok $f1, 'Future', 'acquire returns a Future';
ok $f1->is_ready, 'first acquire resolves immediately';
my $conn1 = $f1->get;
isa_ok $conn1, 'MockConn', 'resolved to connection object';

# Second acquire with pool full: returns pending Future
my $f2 = $pool->acquire;
isa_ok $f2, 'Future', 'second acquire returns a Future';
ok !$f2->is_ready, 'second acquire is pending (pool full)';

# Release resolves the waiter
$pool->release($conn1);
ok $f2->is_ready, 'release resolves the pending Future';
my $conn2 = $f2->get;
isa_ok $conn2, 'MockConn', 'resolved to a connection';

done_testing;
