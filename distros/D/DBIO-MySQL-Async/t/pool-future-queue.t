use strict;
use warnings;
use Test::More;

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use DBIO::MySQL::Async::Pool;

# Subclass Pool to avoid real EV::MariaDB connections. The pool base
# tracks the connection itself — _create_connection just returns one.
{
  package MockConnMySQLAsync;
  sub new { bless { id => $_[1] }, $_[0] }
}

{
  package TestPoolMySQL;
  use base 'DBIO::MySQL::Async::Pool';
  sub _create_connection {
    my ($s, $conninfo) = @_;
    $s->{_next_id}++;
    return MockConnMySQLAsync->new($s->{_next_id});
  }
}

my $pool = TestPoolMySQL->new(conninfo => { host => 'localhost' }, size => 1);
$pool->{_next_id} = 0;

# First acquire: returns an immediately-resolved Future
my $f1 = $pool->acquire;
isa_ok $f1, 'Future', 'acquire returns a Future';
ok $f1->is_ready, 'first acquire resolves immediately';
my $conn1 = $f1->get;
isa_ok $conn1, 'MockConnMySQLAsync', 'resolved to connection object';

# Second acquire with pool full: returns pending Future
my $f2 = $pool->acquire;
isa_ok $f2, 'Future', 'second acquire returns a Future';
ok !$f2->is_ready, 'second acquire is pending (pool full)';

# Release resolves the waiter
$pool->release($conn1);
ok $f2->is_ready, 'release resolves the pending Future';
my $conn2 = $f2->get;
isa_ok $conn2, 'MockConnMySQLAsync', 'resolved to a connection';

done_testing;