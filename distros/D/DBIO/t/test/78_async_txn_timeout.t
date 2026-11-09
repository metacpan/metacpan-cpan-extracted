use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

# karr k397. A transaction had no time limit: a coderef whose Future never
# settles held its connection, and the locks of its transaction, for good.
# txn_timeout (seconds, a connect option of the async storage, no default) ends
# it through the cancel path of karr k274:
#
#   * when the timer runs out before the transaction is over, the transaction
#     is cancelled -- ROLLBACK goes out best-effort and is not waited for, the
#     connection is retired and its slot is free for a fresh one -- and the
#     Future txn_do_async returned FAILS with "transaction timed out after N
#     seconds" (it is not left cancelled, and not left pending);
#   * a transaction that ends first stops the timer, and nothing fails later;
#   * without the option no timer is made;
#   * cancelling the returned Future still cancels the transaction;
#   * a Future class that cannot be cancelled has no cancel path: txn_do_async
#     answers a failed Future saying so before it takes a connection.
#
# The timer is the storage's _delay seam; here a Future the test settles. Needs
# Future.pm: a cancel is what is being tested.

unless (eval { require Future; 1 }) {
  plan skip_all => 'Future not installed: nothing can cancel a Future';
}

{
  package K397C::Conn;
  sub new { bless { id => $_[1] }, $_[0] }
}

{
  package K397C::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection   { K397C::Conn->new(++$_[0]->{_next_id}) }
  sub _shutdown_connection { push @{ $_[0]{closed} }, $_[1]->{id} }
  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{release_log} }, $conn->{id};
    return $self->SUPER::release($conn);
  }
}

{
  package K397C::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { $_[0]{fc} || 'Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }

  sub pool {
    my $self = shift;
    return $self->{pool} ||= K397C::Pool->new(
      conninfo => 'fake', size => 1, future_class => $self->future_class,
    );
  }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{captured} }, $sql;
    return $self->future_class->done;
  }

  sub _delay {
    my ($self, $seconds) = @_;
    my $timer = Future->new;
    push @{ $self->{delays} }, { seconds => $seconds, timer => $timer };
    return $timer;
  }
}

sub new_backend {
  my (%knobs) = @_;
  my $options = delete $knobs{options};
  my $schema  = DBIO::Test->init_schema;
  my $backend = K397C::Backend->new($schema);
  my $owner   = $schema->storage;
  $backend->_owner_storage($owner);
  $owner->_async_context_owner_token($backend->_context_owner_token);
  $backend->{_test_schema_guard} = $schema;
  $backend->{captured} = [];
  $backend->{delays}   = [];
  $backend->{_async_options} = $options || {};
  $backend->{$_} = $knobs{$_} for keys %knobs;
  return $backend;
}

sub error_of { my ($f) = @_; return $f->is_failed ? ($f->failure)[0] : undef }

# --- the timeout ends a transaction whose coderef never settles ------------------
{
  my $backend = new_backend(options => { txn_timeout => 5 });
  my $never   = Future->new;
  my $f = $backend->txn_do_async(sub { $never });

  is scalar @{ $backend->{delays} }, 1, 'timeout: a timer is made';
  is $backend->{delays}[0]{seconds}, 5, 'timeout: of txn_timeout seconds';
  ok !$f->is_ready, 'timeout: the transaction is open';
  is_deeply $backend->{captured}, [ 'BEGIN' ], 'timeout: BEGIN went out';

  $backend->{delays}[0]{timer}->done;

  ok $f->is_failed, 'timeout: the Future fails -- it is not cancelled, and not pending';
  like error_of($f), qr/transaction timed out after 5 seconds/, 'timeout: with the timeout in the message';
  is_deeply $backend->{captured}, [ 'BEGIN', 'ROLLBACK' ],
    'timeout: ROLLBACK went out, best-effort';
  my $pool = $backend->pool;
  is_deeply $pool->{closed}, [ 1 ], 'timeout: the connection was retired';
  is_deeply $pool->{release_log} // [], [], 'timeout: and not released into the pool';
  is $pool->size, 0, 'timeout: its slot is free';
  ok $never->is_cancelled, 'timeout: the coderef\'s own Future was cancelled with the transaction';

  # The slot goes to a fresh connection.
  my $next = $pool->acquire;
  ok $next->is_ready && !$next->is_failed, 'timeout: the next caller gets a fresh connection';
}

# --- a transaction that ends first stops the timer --------------------------------
{
  my $backend = new_backend(options => { txn_timeout => 5 });
  my $f = $backend->txn_do_async(sub { Future->done('v') });

  ok $f->is_ready && !$f->is_failed, 'in time: the transaction commits';
  is(($f->get)[0], 'v', 'in time: with its value');
  ok $backend->{delays}[0]{timer}->is_cancelled, 'in time: the timer was stopped';
  is_deeply $backend->{captured}, [ qw(BEGIN COMMIT) ], 'in time: BEGIN, COMMIT';
  is $backend->pool->available, 1, 'in time: the connection was released';
}
{
  my $backend = new_backend(options => { txn_timeout => 5 });
  my $pending = Future->new;
  my $f = $backend->txn_do_async(sub { $pending });
  $pending->done('late but in time');
  ok $f->is_ready && !$f->is_failed, 'in time, later: the transaction commits';
  $backend->{delays}[0]{timer}->done if !$backend->{delays}[0]{timer}->is_ready;
  ok !$f->is_failed, 'in time, later: a timer that fires afterwards changes nothing';
}

# --- a failing coderef keeps its own error ------------------------------------------
{
  my $backend = new_backend(options => { txn_timeout => 5 });
  my $f = $backend->txn_do_async(sub { Future->fail("coderef failed\n") });
  is error_of($f), "coderef failed\n", 'failing coderef: the transaction fails with its error';
  is_deeply $backend->{captured}, [ qw(BEGIN ROLLBACK) ], 'failing coderef: ROLLBACK';
}

# --- no option, no timer -------------------------------------------------------------
{
  my $backend = new_backend();
  my $f = $backend->txn_do_async(sub { Future->done });
  is scalar @{ $backend->{delays} }, 0, 'no txn_timeout: no timer is made';
  ok $f->is_ready && !$f->is_failed, 'no txn_timeout: the transaction commits';
}

# --- cancelling the Future still cancels the transaction --------------------------------
{
  my $backend = new_backend(options => { txn_timeout => 5 });
  my $f = $backend->txn_do_async(sub { Future->new });
  $f->cancel;
  ok $f->is_cancelled, 'cancel: the caller\'s Future is cancelled';
  is_deeply $backend->{captured}, [ 'BEGIN', 'ROLLBACK' ], 'cancel: ROLLBACK went out';
  is_deeply $backend->pool->{closed}, [ 1 ], 'cancel: the connection was retired';
  ok $backend->{delays}[0]{timer}->is_cancelled, 'cancel: the timer was stopped';
}

# --- a timer that cannot be made -------------------------------------------------------------
{
  package K397C::NoTimer;
  use base 'K397C::Backend';
  sub _delay { die "no timer today\n" }
}
{
  my $backend = new_backend(options => { txn_timeout => 5 });
  bless $backend, 'K397C::NoTimer';
  my $f = $backend->txn_do_async(sub { Future->done });
  ok $f->is_failed, 'no timer: the transaction is refused';
  like error_of($f), qr/no timer today/, 'no timer: with the error of the timer';
  is_deeply $backend->{captured}, [], 'no timer: before anything went out';
}

# --- a Future class that cannot be cancelled ---------------------------------------------------
{
  my $backend = new_backend(options => { txn_timeout => 5 }, fc => 'DBIO::Test::Future');
  my $f = $backend->txn_do_async(sub { DBIO::Test::Future->done });
  ok $f->is_failed, 'not cancellable: txn_do_async fails';
  like $f->{values}[0], qr/txn_timeout needs a Future class that can be cancelled/,
    'not cancellable: and says why';
  is_deeply $backend->{captured}, [], 'not cancellable: before BEGIN';
}

done_testing;
