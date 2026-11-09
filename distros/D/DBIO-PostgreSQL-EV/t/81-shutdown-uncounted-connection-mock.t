use strict;
use warnings;
use Test::More;

# OFFLINE test for karr k88 (4): the pool closes a connection it never counted,
# and closing it asks nothing of the pool's books.
#
# WHY: since core k277 PoolBase::_spawn_connection closes the connection a
# spawn made when the pool was shut down from inside _create_connection -- the
# connection is born into a pool that is gone, shutdown never saw it, and it is
# not in _connections. _shutdown_connection (this distribution's override) is
# then called for a connection the pool never counted, still CONNECTING. The
# override is `$conn->finish`, which must not presuppose the count: it must not
# report the connection dead to the pool through the on_error wrapper of
# _new_connection (a pool that never counted it has nothing to retire), and it
# must leave nothing of the connection behind. Measured against PostgreSQL 18.6
# with EV::Pg 0.07 (t/82-shutdown-uncounted-connection-live.t): finish of a
# connecting connection calls neither on_connect nor on_error, and the loop
# returns dry afterwards.
#
# What this file claims, through the REAL pool over a stand-in EV::Pg:
#   1. a pool shut down from inside _create_connection fails the acquire as
#      shut down and counts no connection;
#   2. the connection the spawn made was closed exactly once, through finish
#      of the fork-safe handle;
#   3. the pool was not told it was dead (_mark_connection_dead) -- it never
#      counted it, and its readiness entry is gone;
#   4. no handler of the closed connection fires afterwards, the loop has
#      nothing left to run (a watcher left standing would keep it going), and
#      the pool stays shut down with nothing counted.
#
# THE ONE SUBSTITUTION is EV::Pg: a connection that is "connecting" on a timer,
# whose finish stops that timer and calls no handler -- what EV::Pg 0.07 does,
# measured in the live twin. 3 and 4 fail should finish ever call on_error of
# a connection still connecting (the stand-in has a switch for it, used below
# to show the claim can fail).

BEGIN {
  package EV::Pg;
  use Scalar::Util ();

  our $FINISH_CALLS_ON_ERROR = 0;
  our @FINISHED;

  sub new {
    my ($class, %args) = @_;
    my $self = bless { on_connect => $args{on_connect}, on_error => $args{on_error}, up => 0 }, $class;
    Scalar::Util::weaken(my $weak = $self);
    # connecting: a timer stands for the handshake's watchers
    $self->{hs} = EV::timer(0.05, 0, sub {
      return unless $weak;
      $weak->{up} = 1;
      $weak->{on_connect}->() if $weak->{on_connect};
    });
    return $self;
  }

  sub is_connected { $_[0]{up} ? 1 : 0 }
  sub socket       { -1 }
  sub pending_count { 0 }

  sub finish {
    my ($self) = @_;
    push @FINISHED, $self;
    delete $self->{hs};
    $self->{up} = 0;
    $self->{on_error}->('connection finished') if $FINISH_CALLS_ON_ERROR && $self->{on_error};
    return;
  }

  $INC{'EV/Pg.pm'} = __FILE__;
}

use EV;
use DBIO::PostgreSQL::EV::Pool;

alarm 60;

{
  package K88::Pool;
  our @ISA = ('DBIO::PostgreSQL::EV::Pool');

  our @MARKED;
  our $CONN;

  # Shut down from inside the creation of the connection: the connection is
  # born into a pool that is gone (core k277).
  sub _create_connection {
    my $self = shift;
    $CONN = $self->SUPER::_create_connection(@_);
    $self->shutdown;
    return $CONN;
  }

  sub _mark_connection_dead {
    my ($self, @args) = @_;
    push @MARKED, $args[0];
    return $self->SUPER::_mark_connection_dead(@args);
  }
}

sub run_case {
  my ($finish_calls_on_error) = @_;
  local $EV::Pg::FINISH_CALLS_ON_ERROR = $finish_calls_on_error;
  @EV::Pg::FINISHED = ();
  @K88::Pool::MARKED = ();
  $K88::Pool::CONN   = undef;

  my $pool = K88::Pool->new(conninfo => 'dbname=k88', max_size => 1);
  my $f = $pool->acquire;

  my $hung = 0;
  EV::now_update();
  my $dog = EV::timer(2, 0, sub { $hung = 1; EV::break });
  $dog->keepalive(0);
  EV::run;
  return ($pool, $f, $hung);
}

{
  my ($pool, $f, $hung) = run_case(0);

  ok $f->is_ready && $f->is_failed, '1: the acquire made from the spawn failed';
  like(($f->failure)[0], qr/shut down/, '1: ... as shut down');
  is scalar @{ $pool->{_connections} || [] }, 0, '1: no connection counted';

  is scalar @EV::Pg::FINISHED, 1, '2: the connection was closed once';
  ok $K88::Pool::CONN && $EV::Pg::FINISHED[0] == $K88::Pool::CONN,
    '2: ... and it is the one the spawn made';
  isa_ok $K88::Pool::CONN, 'DBIO::PostgreSQL::EV::Pool::_Connection', '2: the connection';

  is scalar @K88::Pool::MARKED, 0, '3: the pool was not told the connection died';

  ok !$hung, '4: the loop returned dry, no watcher of the closed connection left';
  ok !$K88::Pool::CONN->is_connected, '4: the closed connection never came up';
  ok $pool->{_shutdown}, '4: the pool is still shut down';
}

# The claim can fail: a finish that reports the connecting connection through
# on_error reaches the pool that never counted it.
{
  my @warned;
  local $SIG{__WARN__} = sub { push @warned, @_ };
  my ($pool, $f, $hung) = run_case(1);
  is scalar @warned, 1, 'control: the pool\'s on_error spoke too';
  is scalar @K88::Pool::MARKED, 1,
    'control: a finish that calls on_error does tell the pool (the claim above is not vacuous)';
}

done_testing;
