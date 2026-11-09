use strict;
use warnings;
use Test::More;

use Future;
use Future::IO;
use Time::HiRes ();
use DBIO::SQLMaker;          # the mock's sql_maker_class
use DBIO::Async::Storage;
use DBIO::Async::Pool;

# OFFLINE test for karr k54: the core's pool limits reach the pool of this
# transport and run on the Future::IO timer.
#
# WHY IT MATTERS. acquire_timeout and max_waiters are core options read when
# the pool is built, off the owning storage. DBIO::Async::Pool used to keep the
# storage back until the pool existed, so the core read nothing: an option the
# caller gave was ignored and the default of 30 seconds applied. Here the
# options are given and the pool must carry them. The timer of acquire_timeout
# is the storage's _delay -- _listen_delay, Future::IO->sleep -- so it needs no
# event loop beyond the one Future::IO runs on.

{
  package Limits42;
  use base 'DBIO::Async::Storage';
  use lib 't/lib';
  use AsyncResetStub;

  sub sql_maker_class           { 'DBIO::SQLMaker' }
  sub _transform_sql            { $_[1] }
  sub _post_insert_sql          { '' }
  sub _normalize_conninfo       { $_[1] }
  sub _conn_ready               { 1 }
  sub _shutdown_pool_connection { }
  sub _create_pool_connection   { { id => ++$_[0]{_next_id} } }
}

sub new_storage {
  my (%opts) = @_;
  my $storage = Limits42->new(undef);
  $storage->{_next_id} = 0;
  $storage->connect_info([{ host => 'localhost', pool_size => 1, %opts }]);
  return $storage;
}

{
  my $pool = new_storage(acquire_timeout => 0.2, max_waiters => 1, reset_timeout => 7)->pool;
  is $pool->{acquire_timeout}, 0.2, 'acquire_timeout given to the connection reaches the pool';
  is $pool->{max_waiters},     1,   '... and so does max_waiters';
  is $pool->{reset_timeout},   7,   '... and reset_timeout';
  is new_storage()->pool->{acquire_timeout}, 30,
    'without the option the pool has core\'s default of 30 seconds';
  is new_storage(acquire_timeout => 0)->pool->{acquire_timeout}, 0,
    'acquire_timeout 0 turns the timeout off';
}

{
  my $storage = new_storage(acquire_timeout => 0.2, max_waiters => 1);
  my $pool    = $storage->pool;
  my $held    = $pool->acquire->get;

  my $waiter = $pool->acquire;
  ok !$waiter->is_ready, 'the second acquire of a pool of one waits';
  my $over = $pool->acquire;
  ok $over->is_failed, 'max_waiters reached: the next caller fails at once';
  like scalar $over->failure, qr/pool exhausted: 1 callers waiting/, '... with core\'s message';

  my $t0 = Time::HiRes::time;
  eval { $waiter->get };
  my $took = Time::HiRes::time - $t0;
  ok $waiter->is_failed, 'the waiting acquire fails when its time is up';
  like scalar $waiter->failure, qr/no pool connection within 0\.2 seconds/,
    '... with core\'s message, from the Future::IO timer';
  cmp_ok $took, '>=', 0.15, '... not before';
  cmp_ok $took, '<', 5, '... and not by a hang';
  is scalar @{ $pool->{_waiters} }, 0, 'the timed-out waiter is no longer queued';

  $pool->release($held);
  ok $pool->acquire->is_ready, 'the pool is not wedged: the connection is there for the next one';
}

done_testing;
