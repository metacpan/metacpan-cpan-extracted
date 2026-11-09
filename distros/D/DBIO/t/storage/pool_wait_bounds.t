use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Storage::PoolBase;
use DBIO::Test::Future ();

# karr k397. A caller of PoolBase::acquire waited for a pool connection with no
# end and no bound: a pool that never frees a connection held every caller --
# and the SQL and binds its Future chain closes over -- for good.
#
# The claims, for a pool of one:
#
#   max_waiters   -- with that many callers queued, the next acquire is a
#                    failed Future at once ("pool exhausted: N callers
#                    waiting") and queues nothing; a slot that frees up is
#                    usable again.
#   acquire_timeout -- a caller that has to wait is timed by the owning
#                    storage's _delay. When the time runs out its waiter leaves
#                    the queue and fails ("no pool connection within N
#                    seconds"); the release that comes later goes to nobody
#                    orphaned (the connection is idle, not lost). A caller
#                    that gets a connection at once arms no timer; one that
#                    is served stops its timer; 0 turns the timeout off; the
#                    default is 30 seconds.
#   the whole wait -- the time a new connection takes to come up counts: a
#                    timeout while the connection is coming up fails the
#                    caller, and the connection that comes up afterwards is
#                    idle, never lost.
#   options       -- read from the owning storage when the pool is not given
#                    them; a value that is no number of seconds or no positive
#                    integer throws, naming the option and never the value; a
#                    pool without a timer takes no positive timeout.
#
# Mock only: a fake owning storage whose _delay hands out Futures the test
# settles by hand, fake connections, no event loop.

{
  package K397::Conn;
  sub new          { my ($class, %args) = @_; bless {%args}, $class }
  sub fire_connect { $_[0]{on_connect}->() }
}

{
  package K397::Storage;
  sub new { bless { delays => [], options => $_[1] || {}, delay_dies => 0 }, $_[0] }
  sub async_option { $_[0]{options}{ $_[1] } }
  sub _delay {
    my ($self, $seconds) = @_;
    die "no timer today\n" if $self->{delay_dies};
    my $timer = $self->{future_class}->new;
    push @{ $self->{delays} }, { seconds => $seconds, timer => $timer };
    return $timer;
  }
}

{
  package K397::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection   { K397::Conn->new(id => ++$_[0]{n}) }
  sub _shutdown_connection { push @{ $_[0]{closed} }, $_[1]{id} }
}

{
  # Connections that come up when the test says so.
  package K397::ColdPool;
  use base 'K397::Pool';
  sub _create_connection {
    my ($self, $conninfo) = @_;
    return $self->_create_ready_connection(conninfo => $conninfo);
  }
  sub _new_connection {
    my ($self, %args) = @_;
    my $conn = K397::Conn->new(%args, id => ++$self->{n});
    push @{ $self->{built} }, $conn;
    return $conn;
  }
}

sub new_pool {
  my (%args) = @_;
  my $fc      = delete $args{future_class} || 'DBIO::Test::Future';
  my $class   = delete $args{class}        || 'K397::Pool';
  my $storage = delete $args{storage} || K397::Storage->new(delete $args{options});
  $storage->{future_class} = $fc;
  my $pool = $class->new(
    conninfo => 'x', size => 1, future_class => $fc, storage => $storage, %args,
  );
  return ($pool, $storage);
}

my @keep;
sub error_of { my ($f) = @_; return $f->is_failed ? ($f->can('failure') ? $f->failure : $f->{values}[0]) : undef }

for my $fc ('DBIO::Test::Future', (eval { require Future; 1 } ? 'Future' : ())) {
  note "future class $fc";

  # --- max_waiters -------------------------------------------------------
  {
    my ($pool) = new_pool(future_class => $fc, max_waiters => 2);
    my $held = $pool->acquire;
    ok $held->is_ready, 'max_waiters: the first caller has the connection';

    my @waiting = map { $pool->acquire } 1 .. 2;
    ok !(grep { $_->is_ready } @waiting), 'max_waiters: two callers are queued';

    my $refused = $pool->acquire;
    ok $refused->is_failed, 'max_waiters: the next caller is refused at once';
    like error_of($refused), qr/pool exhausted: 2 callers waiting\b/,
      'max_waiters: the failure says the pool is exhausted and how many wait';
    is scalar @{ $pool->{_waiters} }, 2, 'max_waiters: the refused caller queued nothing';

    $pool->release($held->get);
    ok $waiting[0]->is_ready && !$waiting[0]->is_failed,
      'max_waiters: the oldest waiter is served by the release';
    my $room = $pool->acquire;
    ok !$room->is_ready && !$room->is_failed,
      'max_waiters: a freed place in the queue takes the next caller';
  }

  # --- acquire_timeout: the queue ------------------------------------------
  {
    my ($pool, $storage) = new_pool(future_class => $fc, acquire_timeout => 5);
    my $held = $pool->acquire;
    is scalar @{ $storage->{delays} }, 0, 'timeout: a caller served at once arms no timer';

    my $waiting = $pool->acquire;
    is scalar @{ $storage->{delays} }, 1, 'timeout: a caller that has to wait arms a timer';
    is $storage->{delays}[0]{seconds}, 5, 'timeout: of acquire_timeout seconds';

    $storage->{delays}[0]{timer}->done;
    ok $waiting->is_failed, 'timeout: the caller fails when the time runs out';
    like error_of($waiting), qr/no pool connection within 5 seconds\b/,
      'timeout: the failure names the timeout';
    is scalar @{ $pool->{_waiters} }, 0, 'timeout: the waiter has left the queue';

    $pool->release($held->get);
    is $pool->available, 1, 'timeout: the release hands the connection to nobody orphaned: it is idle';
    ok $pool->acquire->is_ready, 'timeout: and the next caller gets it at once';
  }

  # --- acquire_timeout: a served caller stops its timer ---------------------
  {
    my ($pool, $storage) = new_pool(future_class => $fc, acquire_timeout => 5);
    my $held    = $pool->acquire;
    my $waiting = $pool->acquire;
    $pool->release($held->get);
    ok $waiting->is_ready && !$waiting->is_failed, 'served: the release serves the waiting caller';

    $storage->{delays}[0]{timer}->done;
    ok !$waiting->is_failed, 'served: a timer that fires afterwards changes nothing';
    is $pool->available, 0, 'served: the connection is still the caller\'s';
  }

  # --- acquire_timeout: the connection coming up counts ---------------------
  {
    my ($pool, $storage) = new_pool(
      future_class => $fc, class => 'K397::ColdPool', acquire_timeout => 7,
    );
    my $caller = $pool->acquire;
    ok !$caller->is_ready, 'coming up: the caller waits for the connection to come up';
    is scalar @{ $storage->{delays} }, 1, 'coming up: and its wait is timed';
    is $storage->{delays}[0]{seconds} > 6.9 && $storage->{delays}[0]{seconds} <= 7 ? 1 : 0, 1,
      'coming up: with the timeout, counted from the call';

    $storage->{delays}[0]{timer}->done;
    ok $caller->is_failed, 'coming up: the caller fails when the time runs out';
    like error_of($caller), qr/no pool connection within 7 seconds/, 'coming up: with the timeout';

    $pool->{built}[0]->fire_connect;
    is $pool->available, 1, 'coming up: the connection that comes up afterwards is idle, not lost';
    is $pool->size, 1, 'coming up: and counted once';
  }

  # --- the wait in the queue and the wait for the connection share one clock
  {
    my ($pool, $storage) = new_pool(
      future_class => $fc, class => 'K397::ColdPool', acquire_timeout => 9,
    );
    my $first = $pool->acquire;                 # connection 1 coming up
    $pool->{built}[0]->fire_connect;
    ok $first->is_ready, 'one clock: the first caller has its connection';
    my $second = $pool->acquire;                # queued behind it
    my $queued_timer = $#{ $storage->{delays} };

    # The connection is retired: its slot goes to the queued caller, on a
    # fresh connection that has to come up first.
    $pool->_retire_in_use_connection($first->get);
    ok !$second->is_ready, 'one clock: the queued caller now waits for a connection to come up';
    is $#{ $storage->{delays} }, $queued_timer + 1, 'one clock: that stage is timed too';
    my $stage = $storage->{delays}[-1]{seconds};
    ok $stage > 8.9 && $stage <= 9, 'one clock: with what is left of the one timeout, not a new one';

    $storage->{delays}[-1]{timer}->done;
    ok $second->is_failed, 'one clock: the caller fails when that time runs out';
    like error_of($second), qr/no pool connection within 9 seconds/, 'one clock: with the timeout';
    $pool->{built}[1]->fire_connect;
    is $pool->available, 1, 'one clock: the connection that comes up afterwards is idle';
  }

  # --- 0 turns the timeout off, 30 is the default -----------------------------
  {
    my ($pool, $storage) = new_pool(future_class => $fc, acquire_timeout => 0);
    push @keep, $pool->acquire;
    push @keep, $pool->acquire;
    is scalar @{ $storage->{delays} }, 0, 'acquire_timeout 0: no timer';
  }
  {
    my ($pool, $storage) = new_pool(future_class => $fc);
    push @keep, $pool->acquire;
    push @keep, $pool->acquire;
    is $storage->{delays}[0]{seconds}, 30, 'default: 30 seconds';
  }

  # --- options come from the owning storage -------------------------------------
  {
    my ($pool, $storage) = new_pool(
      future_class => $fc, options => { acquire_timeout => 3, max_waiters => 1 },
    );
    push @keep, $pool->acquire;
    push @keep, $pool->acquire;
    is $storage->{delays}[0]{seconds}, 3, 'storage options: acquire_timeout is read from the storage';
    ok $pool->acquire->is_failed, 'storage options: so is max_waiters';
  }

  # --- a timer that cannot be made ---------------------------------------------
  {
    my ($pool, $storage) = new_pool(future_class => $fc);
    push @keep, $pool->acquire;
    $storage->{delay_dies} = 1;
    my $caller = $pool->acquire;
    ok $caller->is_failed, 'no timer: the caller fails instead of waiting untimed';
    like error_of($caller), qr/no timer today/, 'no timer: with the error of the timer';
    is scalar @{ $pool->{_waiters} }, 0, 'no timer: and is not queued';
  }
}

# --- validation ---------------------------------------------------------------
for my $bad (
  [ acquire_timeout => 'soon' ], [ acquire_timeout => -1 ], [ acquire_timeout => [] ],
  [ max_waiters => 0 ], [ max_waiters => 1.5 ], [ max_waiters => 'many' ],
) {
  my ($name, $value) = @$bad;
  throws_ok { new_pool($name => $value) } qr/Connect option '$name' takes/,
    "invalid $name is refused";
  my $message = eval { new_pool($name => $value); 1 } ? '' : "$@";
  unlike $message, qr/soon|many|1\.5/, "the message for $name names no value";
}

{
  throws_ok {
    K397::Pool->new(conninfo => 'x', future_class => 'DBIO::Test::Future', acquire_timeout => 5)
  } qr/acquire_timeout needs a timer/, 'a pool without an owning storage takes no positive timeout';
  lives_ok {
    K397::Pool->new(conninfo => 'x', future_class => 'DBIO::Test::Future')
  } 'a pool without an owning storage works with the timeout off by default';
}

is(DBIO::Storage::PoolBase->assert_limit_option(txn_timeout => 0.5), 1, 'txn_timeout takes a fraction of a second');
throws_ok { DBIO::Storage::PoolBase->assert_limit_option(txn_timeout => 0) }
  qr/Connect option 'txn_timeout' takes a number of seconds above 0/, 'txn_timeout 0 is refused';

done_testing;
