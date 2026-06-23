use strict;
use warnings;
use Test::More;

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use DBIO::Storage::PoolBase;

{
  package MockConn;
  sub new { bless { id => $_[1], closed => 0 }, $_[0] }
  sub close { $_[0]->{closed} = 1 }
}

{
  package TestPool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection {
    my ($self, $conninfo) = @_;
    $self->{_seen_conninfo} = $conninfo;
    return MockConn->new(++$self->{_next_id});
  }

  sub _shutdown_connection { $_[1]->close }

  sub _transform_conninfo { "transformed:$_[1]" }
}

# --- constructor contract ---

eval { TestPool->new };
like $@, qr/conninfo or conninfo_provider required/, 'new requires conninfo';

my $pool = TestPool->new(conninfo => 'fake', size => 1);
isa_ok $pool, 'DBIO::Storage::PoolBase';
isa_ok $pool, 'DBIO::Storage::Pool';
is $pool->max_size, 1, 'max_size from size arg';
is $pool->size, 0, 'no connections yet';

# --- acquire / waiter queue (the shared mechanics) ---

my $f1 = $pool->acquire;
isa_ok $f1, 'Future', 'acquire returns a Future';
ok $f1->is_ready, 'first acquire resolves immediately';
my $conn1 = $f1->get;
isa_ok $conn1, 'MockConn', 'resolved to connection object';
is $pool->size, 1, 'one connection created';
is $pool->{_seen_conninfo}, 'transformed:fake', '_transform_conninfo applied before _create_connection';

my $f2 = $pool->acquire;
ok !$f2->is_ready, 'second acquire is pending (pool full)';

$pool->release($conn1);
ok $f2->is_ready, 'release resolves the pending waiter';
isa_ok scalar $f2->get, 'MockConn', 'waiter got the connection';
is $pool->available, 0, 'connection handed to waiter, not idled';

# --- release with no waiters idles the connection ---

$pool->release($conn1);
is $pool->available, 1, 'released connection is idle';

my $f3 = $pool->acquire;
ok $f3->is_ready, 'idle connection acquired without creating new one';
is $pool->size, 1, 'still one connection';

# --- acquire_txn behaves like acquire ---

my $pool2 = TestPool->new(conninfo => 'fake', size => 2);
my $ft = $pool2->acquire_txn;
ok $ft->is_ready, 'acquire_txn resolves with capacity';
isa_ok scalar $ft->get, 'MockConn', 'acquire_txn yields connection';

# --- conninfo_provider is consulted per connection ---

my @provided;
my $pool3 = TestPool->new(
  conninfo_provider => sub { push @provided, 1; 'dynamic' },
  size => 2,
);
$pool3->acquire->get;
is scalar @provided, 1, 'conninfo_provider called';
is $pool3->{_seen_conninfo}, 'transformed:dynamic', 'provider result transformed';

# --- shutdown closes via _shutdown_connection hook ---

my $conn = $f3->get;
$pool->shutdown;
is $conn->{closed}, 1, 'shutdown calls _shutdown_connection';
is $pool->size, 0, 'connections cleared';
is $pool->available, 0, 'idle pool cleared';

# --- _create_connection is a required hook ---

{
  package BarePool;
  use base 'DBIO::Storage::PoolBase';
}
my $bare = BarePool->new(conninfo => 'x');
eval { $bare->acquire };
like $@, qr/Subclass must override _create_connection/, '_create_connection required';
$bare->{_connections} = [];  # avoid noise from DESTROY/shutdown

# --- future_class override ---

is +TestPool->new(conninfo => 'x')->future_class, 'Future', 'default future_class';
is +TestPool->new(conninfo => 'x', future_class => 'Future')->future_class,
  'Future', 'future_class constructor arg honoured';
eval { TestPool->new(conninfo => 'x', future_class => 'No::Such::Future::Class') };
like $@, qr/Cannot load future class/, 'unloadable future_class croaks in new';

done_testing;
