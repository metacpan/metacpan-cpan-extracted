use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Storage::PoolBase;
use DBIO::Test::Future ();

{
  package MockConn;
  sub new { bless { id => $_[1], closed => 0, close_count => 0 }, $_[0] }
  sub close { $_[0]->{closed} = 1; $_[0]->{close_count}++ }
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

my $pool = TestPool->new(
  conninfo     => 'fake',
  size         => 1,
  future_class => 'DBIO::Test::Future',
);
isa_ok $pool, 'DBIO::Storage::PoolBase';
isa_ok $pool, 'DBIO::Storage::Pool';
is $pool->max_size, 1, 'max_size from size arg';
is $pool->size, 0, 'no connections yet';

# --- acquire / waiter queue (the shared mechanics) ---

my $f1 = $pool->acquire;
isa_ok $f1, 'DBIO::Test::Future', 'acquire returns a Future';
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

my $pool2 = TestPool->new(
  conninfo     => 'fake',
  size         => 2,
  future_class => 'DBIO::Test::Future',
);
my $ft = $pool2->acquire_txn;
ok $ft->is_ready, 'acquire_txn resolves with capacity';
isa_ok scalar $ft->get, 'MockConn', 'acquire_txn yields connection';

# --- conninfo_provider is consulted per connection ---

my @provided;
my $pool3 = TestPool->new(
  conninfo_provider => sub { push @provided, 1; 'dynamic' },
  size              => 2,
  future_class      => 'DBIO::Test::Future',
);
$pool3->acquire->get;
is scalar @provided, 1, 'conninfo_provider called';
is $pool3->{_seen_conninfo}, 'transformed:dynamic', 'provider result transformed';

# --- shutdown is terminal and settles queued acquires ---

my $held = $f3->get;
my $waiter_one = $pool->acquire;
my $waiter_two = $pool->acquire;
ok !$waiter_one->is_ready && !$waiter_two->is_ready,
  'both acquires are queued before shutdown';
is scalar @{ $pool->{_waiters} }, 2,
  'both raw slot waiters are held by the queue before shutdown';

my @queue_sizes_during_failure;
for my $waiter ($waiter_one, $waiter_two) {
  $waiter->then(undef, sub {
    push @queue_sizes_during_failure, scalar @{ $pool->{_waiters} };
    return;
  });
}

$pool->shutdown;
is_deeply \@queue_sizes_during_failure, [0, 0],
  'all waiters are detached before their failure callbacks run';
for my $case (
  [ $waiter_one, 'first queued waiter' ],
  [ $waiter_two, 'second queued waiter' ],
) {
  my ($waiter, $label) = @$case;
  ok $waiter->is_ready && $waiter->is_failed,
    "$label fails during shutdown";
  eval { $waiter->get };
  like $@, qr/Connection pool has been shut down/,
    "$label receives the stable shutdown diagnostic";
}
is_deeply $pool->{_waiters}, [], 'waiters remain absent after settlement';
is $held->{closed}, 1, 'shutdown calls _shutdown_connection';
is $held->{close_count}, 1, 'shutdown closes the held connection exactly once';
is $pool->size, 0, 'connections cleared';
is $pool->available, 0, 'idle pool cleared';

$pool->release($held);
is_deeply $pool->{_idle}, [], 'late release cannot repopulate the idle list';
is_deeply $pool->{_waiters}, [], 'late release cannot hand the connection to a waiter';
ok $waiter_one->is_failed && $waiter_two->is_failed,
  'late release cannot revive either failed waiter';

for my $method (qw(acquire acquire_txn)) {
  my $future;
  lives_ok { $future = $pool->$method }
    "$method after shutdown does not throw synchronously";

  my $is_future = defined($future)
    && eval { $future->isa('DBIO::Test::Future') };
  ok $is_future, "$method after shutdown still returns a Future";
  if ($is_future) {
    ok $future->is_ready && $future->is_failed,
      "$method after shutdown returns a failed Future";
    eval { $future->get };
    like $@, qr/Connection pool has been shut down/,
      "$method names terminal shutdown";
  }
  else {
    fail "$method after shutdown returns a failed Future";
    fail "$method names terminal shutdown";
  }
}

is_deeply $pool->{_connections}, [],
  'post-shutdown acquires cannot create a new connection';
is_deeply $pool->{_idle}, [],
  'post-shutdown acquires cannot populate the idle list';
is_deeply $pool->{_waiters}, [],
  'post-shutdown acquires cannot enqueue a waiter';

$pool->shutdown;
is $held->{close_count}, 1, 'repeated shutdown does not close twice';

# --- _create_connection is a required hook ---

{
  package BarePool;
  use base 'DBIO::Storage::PoolBase';
}
my $bare = BarePool->new(
  conninfo     => 'x',
  future_class => 'DBIO::Test::Future',
);
# acquire() no longer lets ANY spawn failure escape as an exception --
# it is contracted to return a Future and now always does, this case included.
# The required-hook error is not softened by that: it rides the Future verbatim
# and ->get rethrows it, which is what a caller that goes on to use the
# connection gets.
my $bare_f = $bare->acquire;
ok $bare_f->is_failed, '_create_connection required (a failed Future, not a throw)';
eval { $bare_f->get };
like $@, qr/Subclass must override _create_connection/,
  'and the failure names the hook the subclass has to supply';
$bare->{_connections} = [];  # avoid noise from DESTROY/shutdown

# --- future_class override ---

my $unconfigured = bless {
  _connections => [],
  _idle        => [],
  _waiters     => [],
}, 'TestPool';
is $unconfigured->future_class, 'Future', 'default future_class';
is +TestPool->new(conninfo => 'x', future_class => 'DBIO::Test::Future')->future_class,
  'DBIO::Test::Future', 'future_class constructor arg honoured';
eval { TestPool->new(conninfo => 'x', future_class => 'No::Such::Future::Class') };
like $@, qr/Cannot load future class/, 'unloadable future_class croaks in new';

done_testing;
