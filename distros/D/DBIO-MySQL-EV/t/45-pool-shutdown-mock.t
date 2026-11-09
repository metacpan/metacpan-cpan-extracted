use strict;
use warnings;
use Test::More;
use Scalar::Util qw( refaddr );

# OFFLINE test for karr k67, k90 (point 5) and k82: how the pool closes a
# connection, and what the query executor keeps for a handle that is gone.
#
# k67 / k90.5: Pool::_shutdown_connection called $mdb->close_async without a
# callback. EV::MariaDB 0.08 croaks on that ("Usage: EV::MariaDB::close_async(
# self, cb)") and, with a callback, on a handle that is still connecting ("not
# connected") -- and core hands this seam connections the pool never counted
# as connected. The error was swallowed, so the connection was never closed.
# The pool now calls finish, which takes a handle in any state.
#
# k82: the executor keeps %FRAME / %IN_FLIGHT / %AFTER per address of the
# handle. A handle that went away with a statement in flight left a count
# behind, and a later handle at the same address read it as work in flight:
# execute_when_idle queued a statement for ever. forget drops all three where
# a handle goes away.
#
# StrictMDB is as strict as the original: close_async croaks without a
# callback and on a handle that is not connected, finish takes no argument.

use EV;
use DBIO::MySQL::EV::Storage;
use DBIO::MySQL::EV::Pool;
use DBIO::MySQL::EV::QueryExecutor;

{
  package StrictMDB;
  use Carp ();

  our @CALLS;   # "finish" / "close_async", in order, for every handle
  our @SENT;    # { sql, cb } of every query

  sub new {
    my ($class, %args) = @_;
    # Never connects by itself: the handle stays in the state "connecting".
    return bless { connected => 0, args => \%args }, $class;
  }
  sub is_connected  { $_[0]{connected} }
  sub socket        { -1 }
  sub pending_count { 0 }
  sub finish {
    Carp::croak('Usage: EV::MariaDB::finish(self)') unless @_ == 1;
    push @CALLS, 'finish';
    $_[0]{connected} = 0;
    return;
  }
  sub close_async {
    Carp::croak('Usage: EV::MariaDB::close_async(self, cb)') unless @_ == 2;
    Carp::croak('not connected') unless $_[0]{connected};
    push @CALLS, 'close_async';
    $_[1]->(1);
    return;
  }
  sub query { my ($self, $sql, $cb) = @_; push @SENT, { sql => $sql, cb => $cb }; return }
}

{
  no warnings 'redefine';
  *DBIO::MySQL::EV::Pool::_new_connection = sub { shift; StrictMDB->new(@_) };
}

alarm 60;

# -----------------------------------------------------------------------------
# k67: a handle that is still connecting is closed, without a croak.
# -----------------------------------------------------------------------------
{
  @StrictMDB::CALLS = ();
  my $storage = DBIO::MySQL::EV::Storage->new(undef);
  $storage->connect_info([ { host => 'fake', database => 'fake', pool_size => 1 }, {} ]);
  my $pool = $storage->pool;
  my $f    = $pool->acquire;            # spawns a handle; it never connects
  my ($conn) = @{ $pool->{_connections} };
  ok $conn && !$conn->is_connected, 'k67: the pool holds a handle that is still connecting';

  my $ok = eval { $pool->_shutdown_connection($conn); 1 };
  ok $ok, 'k67: closing it does not croak' or diag $@;
  is_deeply \@StrictMDB::CALLS, ['finish'], 'k67: it was finished, once, without an argument';

  @StrictMDB::CALLS = ();
  $storage->disconnect;
  ok !grep({ $_ eq 'close_async' } @StrictMDB::CALLS), 'k67: disconnect never calls close_async';
  is scalar(grep { $_ eq 'finish' } @StrictMDB::CALLS), 1, 'k67: disconnect finished the handle';
}

# -----------------------------------------------------------------------------
# k82: a handle that goes away leaves nothing behind for the next at its address.
# -----------------------------------------------------------------------------
my $executor = DBIO::MySQL::EV::QueryExecutor->new;

sub leaves_work_in_flight {
  my ($mdb) = @_;
  @StrictMDB::SENT = ();
  $executor->execute($mdb, 'SELECT 1', []);   # never answered
  is scalar @StrictMDB::SENT, 1, 'a statement is in flight on the handle';
}

sub idle_start_is_immediate {
  my ($mdb, $label) = @_;
  @StrictMDB::SENT = ();
  $executor->execute_when_idle($mdb, 'ROLLBACK', []);
  is scalar(grep { $_->{sql} eq 'ROLLBACK' } @StrictMDB::SENT), 1, $label;
}

{
  my $mdb = StrictMDB->new;
  leaves_work_in_flight($mdb);
  @StrictMDB::SENT = ();
  $executor->execute_when_idle($mdb, 'ROLLBACK', []);
  is scalar @StrictMDB::SENT, 0, 'k82: with the count left over, the statement waits (the inherited state)';

  # The handle is shut down; a new one comes up at the same key.
  DBIO::MySQL::EV::Pool->_shutdown_connection($mdb);
  idle_start_is_immediate($mdb, 'k82: after the shutdown, a handle at the same key starts from nothing');
}

{
  my $mdb = StrictMDB->new;
  leaves_work_in_flight($mdb);
  # The fork watcher's callback of a child: it finishes the inherited copies.
  my $pool = bless { _mysql_inherited => [$mdb] }, 'ForkHolder';   # the callback reads only this slot
  DBIO::MySQL::EV::Pool::_mysql_pool_fork_cb($pool, $$)->();
  idle_start_is_immediate($mdb, 'k82: a handle the fork guard finished is forgotten too');
}

{
  my $mdb = StrictMDB->new;
  ok eval { DBIO::MySQL::EV::QueryExecutor->forget($mdb); DBIO::MySQL::EV::QueryExecutor->forget(undef); 1 },
    'k82: forget of an unknown handle and of undef does nothing';
}

# -----------------------------------------------------------------------------
# k98: a statement waiting behind others (execute_when_idle) is failed with a
# DBIO::Exception when the handle goes away -- never left pending for ever.
# -----------------------------------------------------------------------------
sub waiting_on {
  my ($mdb, $sql) = @_;
  $executor->execute($mdb, 'SELECT 1', []);          # in flight, never answered
  return $executor->execute_when_idle($mdb, $sql, []);
}

sub says_torn_down {
  my ($f, $label) = @_;
  ok $f->is_failed, "$label: the Future failed";
  my ($err) = $f->failure;
  isa_ok $err, 'DBIO::Exception', "$label: the failure";
  like "$err", qr/torn down/, "$label: the message names the teardown";
  like "$err", qr/not sent/,  "$label: ... and that the statement was not sent";
}

{
  my $mdb = StrictMDB->new;
  @StrictMDB::SENT = ();
  my $w1 = waiting_on($mdb, 'ROLLBACK');
  my $w2 = $executor->execute_when_idle($mdb, 'COMMIT', []);
  ok !$w1->is_ready && !$w2->is_ready, 'k98: both statements wait';
  DBIO::MySQL::EV::QueryExecutor->forget($mdb);
  says_torn_down($w1, 'k98 forget (first)');
  says_torn_down($w2, 'k98 forget (second)');
  is scalar(grep { $_->{sql} =~ /ROLLBACK|COMMIT/ } @StrictMDB::SENT), 0, 'k98: neither was sent';
}

{
  my $mdb = StrictMDB->new;
  my $w = waiting_on($mdb, 'ROLLBACK');
  DBIO::MySQL::EV::Pool->_shutdown_connection($mdb);
  says_torn_down($w, 'k98 Pool::_shutdown_connection');
}

{
  my $mdb = StrictMDB->new;
  my $w1 = waiting_on($mdb, 'ROLLBACK');
  my $w2 = $executor->execute_when_idle($mdb, 'COMMIT', []);
  $w1->cancel;
  DBIO::MySQL::EV::QueryExecutor->forget($mdb);
  ok $w1->is_cancelled, 'k98: a cancelled waiter stays cancelled';
  says_torn_down($w2, 'k98 next to a cancelled one');
}

{
  # The real pattern: finish calls back the statement in flight, which would
  # start the waiting one against the finished handle ("not connected").
  package FinishingMDB;
  our @ISA = ('StrictMDB');
  sub query {
    my ($self, $sql, $cb) = @_;
    Carp::croak('not connected') unless $self->{connected};
    push @{ $self->{cbs} }, $cb;
    return;
  }
  sub finish {
    my $self = shift;
    $self->{connected} = 0;
    $_->(undef, 'connection finished') for splice @{ $self->{cbs} || [] };
    return;
  }
}

{
  my $mdb = FinishingMDB->new;
  $mdb->{connected} = 1;
  my $w = waiting_on($mdb, 'ROLLBACK');
  DBIO::MySQL::EV::Pool->_shutdown_connection($mdb);
  says_torn_down($w, 'k98 finish calls back the statement in flight');
}

{
  # Reentrancy: an on_fail callback queues a statement on the same handle and
  # forgets it again; the queue was taken out before the Futures were failed.
  my $mdb = StrictMDB->new;
  my $w1 = waiting_on($mdb, 'ROLLBACK');
  my $w2 = $executor->execute_when_idle($mdb, 'COMMIT', []);
  my (@order, $late);
  $w1->on_fail(sub {
    push @order, 'w1';
    $executor->execute($mdb, 'SELECT 2', []);
    $late = $executor->execute_when_idle($mdb, 'SELECT 3', []);
    DBIO::MySQL::EV::QueryExecutor->forget($mdb);
  });
  $w2->on_fail(sub { push @order, 'w2' });
  DBIO::MySQL::EV::QueryExecutor->forget($mdb);
  is_deeply \@order, [qw(w1 w2)], 'k98: waiters fail oldest first, each exactly once, despite reentry';
  says_torn_down($late, 'k98 queued from inside a failure callback');
}

done_testing;
