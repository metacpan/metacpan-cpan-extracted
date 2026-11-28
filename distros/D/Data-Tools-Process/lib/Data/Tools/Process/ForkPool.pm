##############################################################################
#
#  Data::Tools::Process::ForkPool fork process control pool
#  Copyright (c) 2026 Vladi Belperchinov-Shabanski "Cade"
#        <cade@noxrun.com>
#  http://cade.noxrun.com/
#
#  GPL
#
##############################################################################
#
#  NOTE: all forked processes of a pool are placed in the pool's own process
#  group (pgrp) by the fork pool manager. the pool reaps and signals its
#  forked processes by that pgrp, so forked processes must NOT change their
#  pgrp (no setpgrp(), setsid(), daemonizing, etc.). a forked process which
#  leaves the pool's pgrp will never be reaped or signalled by the pool.
#  a forked process which runs its own (nested) fork pool places its own
#  forked processes in a new pgrp, so they are not reached by the outer
#  pool's fpool_signal_all(), fpool_stop_all() or fpool_kill_all(). the
#  forked process must stop its own pools itself.
#
#  NOTE: when fork pools are used, they should be the only means of forking
#  processes in the supervisor. the pools are not meant to be mixed with bare
#  fork(), Data::Tools::Process::Forks or any other code which calls
#  waitpid( -1, ... ) or wait(). such code may reap the pool's forked
#  processes, then the pool never sees them exit: their count never drops
#  and the pool's pgrp is kept after the group is gone, so later its number
#  may be reused and fpool_signal_all() could signal an unrelated pgrp.
#  $SIG{ 'CHLD' } = 'IGNORE' has the same effect (children are auto-reaped).
#  system(), backticks (qx//) and piped open() are safe to use in the
#  supervisor: they fork internally but wait only for their own child pid.
#
#  NOTE: signals are NOT propagated to the pool's forked processes.
#  terminal signals (Ctrl-C INT, Ctrl-\ QUIT, Ctrl-Z TSTP, HUP on terminal
#  close) are sent only to the terminal's foreground pgrp, which is the
#  supervisor's own pgrp, not the pool's one. signals sent to the
#  supervisor's pid or pgrp (kill, shell job control) do not reach the pool
#  either.
#
#  the fork pool does not install signal handlers. what to do on a signal is
#  high-level logic, and there can be multiple pools, so the supervisor
#  code must catch the signals it cares about and propagate them to each
#  pool with fpool_signal_all(), fpool_stop_all() or fpool_kill_all().
#  signal handlers should only set a flag, the main loop should do the rest.
#
#  forked processes inherit the supervisor's %SIG handlers. the forked sub
#  should set its own handlers (or reset them to 'DEFAULT') first.
#
#  if the supervisor dies without stopping the pools (uncaught signal, KILL,
#  crash), forked processes keep running. they can detect this by EOF from
#  fpool_recv_super() (returns undef) or by getppid() change.
#
#  NOTE: forked processes finish with exit(), so END blocks and destructors
#  of objects inherited from the supervisor DO run in forked processes too.
#  this is intentional, some END blocks must run in the forked processes.
#  END blocks which must run only in the supervisor should check the pid:
#
#    my $SUPER_PID = $$;
#    END { if( $$ == $SUPER_PID ) { ...supervisor only cleanup... } }
#
#  inherited DBI handles should have AutoInactiveDestroy set, otherwise a
#  forked process exit closes the supervisor's database connection.
#
#  NOTE: messages sent by a forked process right before it exits may be lost.
#  when an exited process is reaped (fpool_wait_one(), fpool_wait_all() or
#  fpool_manage(), which reaps before reading), its socket is closed and its
#  unread and queued messages are discarded. a forked process which must
#  deliver a result before exit should wait for an acknowledge message from
#  the supervisor (fpool_recv_super()) before it returns.
#
##############################################################################
package Data::Tools::Process::ForkPool;
use strict;
use Exporter;
use POSIX qw( WNOHANG );
use IO::Poll qw( POLLIN POLLHUP POLLERR );
use Net::Tools::Socket::Pair;
use Net::Tools::Socket::Err;
use Data::Dumper;
use Exception::Sink;

our $VERSION = '1.61';

our @ISA    = qw( Exporter );
our @EXPORT = qw(
                  fpool_manage
                  fpool_wait_all
                  fpool_wait_one
                  fpool_fork_one

                  fpool_stats

                  fpool_update_state
                  fpool_count
                  fpool_busy_count

                  fpool_signal_all
                  fpool_stop_all
                  fpool_kill_all

                  fpool_send_to
                  fpool_recv_from

                  fpool_send_super
                  fpool_recv_super
                  fpool_iam_busy
                  fpool_iam_idle
                );

# max queued non-state messages per forked process, 0 means no limit.
# when full, the oldest messages are discarded and counted in MSG_DROPPED.
our $MSG_QUEUE_MAX = 0;

my %POOLS;
my $SUPER_SOCK; # uplink messages socket


sub fpool_manage
{
  my $pool = uc shift; # pool name
  my $fsub =    shift; # subroutine to fork
  my $min  =    shift; # min fork count for this pool
  my $max  =    shift; # max
  my $step =    shift; # step to increase if all forked are busy, may overflow to max+step-1, then waits to fall to max
  # rest of @_ are passed to $fsub

  return undef unless ref( $fsub ) eq 'CODE';

  $min  = 0    if $min < 0 or ! $min;
  $max  = $min if $max < 0 or ! $max or $max < $min;
  $step = int( $max / 10 ) + 1 if $step <= 0;

  my $phr = $POOLS{ $pool } ||= {};

  fpool_wait_all( $pool );
  fpool_update_state( $pool );

  my $fc = $phr->{ 'FORKS_COUNT' } || 0;
  my $bc = $phr->{ 'BUSY_COUNT'  } || 0;

  my $z = 0;
  if( $fc < $min )
    {
    $z = $min - $fc;  # fill up to min
    $z = $step if $z < $step; # step need to keep up
    }
  elsif( $fc < $max and $bc >= $fc )
    {
    # all busy, grow by step. empty pool counts as all busy (0 >= 0), so with
    # min 0, step new processes are forked whenever the pool is empty
    $z = $step;
    }

  my $nc = 0; # new forks count
  while( $z-- > 0 )
    {
    $nc++ if fpool_fork_one( $pool, $fsub, @_ );
    }

  return $nc;
}

sub fpool_fork_one
{
  my $pool = uc shift; # pool name
  my $fsub =    shift; # subroutine to fork
  # rest of @_ are passed to $fsub

  return undef unless ref( $fsub ) eq 'CODE';
  my $phr = $POOLS{ $pool } ||= {}; # creates the pool if needed

  my ( $super_sock, $forked_sock ) = socketpair_create();
  return undef unless $super_sock and $forked_sock;

  my $pid = fork();
  if( ! defined $pid )
    {
    # error, but will still be in the parent
    close( $super_sock );
    close( $forked_sock );
    return undef;
    }

  if( $pid )
    {
    # print "--> forked [$pid]\n";
    # supervisor here
    close( $super_sock );
    $phr->{ 'PGRP' } = $pid if $phr->{ 'FORKS_COUNT' } == 0; # this is first fork, create new pgrp
    setpgrp( $pid, $phr->{ 'PGRP' } );

    $phr->{ 'PIDS' }{ $pid } = { 'SOCK' => $forked_sock };
    $phr->{ 'FORKS_COUNT' }++;
    $phr->{ 'IO::POLL' } ||= IO::Poll->new();
    $phr->{ 'IO::POLL' }->mask( $forked_sock => POLLIN );
    $phr->{ 'FH_PID_MAP' }{ $forked_sock } = $pid;
    return $pid;
    }

  # forked here
  # print "           [$$] here\n";
  # pool's pgrp, must not be changed by the forked process, see NOTE at the top
  $phr->{ 'PGRP' } ||= $$;
  setpgrp( $$, $phr->{ 'PGRP' } );
  __fpool_reset(); # allow forked minion's own fork pools

  close( $forked_sock );
  $SUPER_SOCK = $super_sock;

  # never return to the parent's code, even if $fsub dies inside parent's eval
  my $ex = eval { $fsub->( @_ ) };
  if( $@ )
    {
    print STDERR $@;
    exit 255;
    }
  # exit() runs END blocks and destructors here too, see NOTE at the top
  exit $ex;
}

# reaps all already exited processes of specified pool, does not block
# returns count of reaped processes
sub fpool_wait_all
{
  my $pool = uc shift; # pool name
  my $to   = shift; # timeout in seconds, waits up to it for all to exit

  my $phr  = $POOLS{ $pool } or return undef;
  return undef unless $phr->{ 'FORKS_COUNT' } > 0;

  my $xc;

  $to = time() + $to if $to > 0;
  while( $phr->{ 'FORKS_COUNT' } > 0 )
    {
    my ( $pid, $exit, $xsig ) = fpool_wait_one( $pool );
    if( $pid )
      {
      $xc++;
      # print "    <-- exit ( $pid, $exit, $xsig, $pool )\n";
      next;
      }
    last unless $to > 0 and time() < $to;
    sleep(1);
    }

  return $xc;
}

# reaps one or none already exited process of specified pool, does not block
sub fpool_wait_one
{
  my $pool = uc shift; # pool name
  my $phr  = $POOLS{ $pool } or return wantarray ? () : undef;
  return wantarray ? () : undef unless $phr->{ 'FORKS_COUNT' } > 0;

  my $pid = waitpid( - $phr->{ 'PGRP' }, WNOHANG );
  return wantarray ? () : undef if $pid <= 0;

  my $status = $?;
  my $exit   = $status >> 8;       # exit code
  my $xsig   = $status & 127;      # exit signal

  my $sock = $phr->{ 'PIDS' }{ $pid }{ 'SOCK' };
  if( $sock )
    {
    $phr->{ 'IO::POLL' }->remove( $sock ) if $phr->{ 'IO::POLL' };
    delete $phr->{ 'FH_PID_MAP' }{ $sock };
    close( $sock );
    }
  my $pr = delete $phr->{ 'PIDS' }{ $pid };
  $phr->{ 'FORKS_COUNT' }--;
  $phr->{ 'BUSY_COUNT'  }-- if $pr->{ 'BUSY' };
  delete $phr->{ 'PGRP' } if $phr->{ 'FORKS_COUNT' } == 0;

  # print "    <-- exit ( $pid, $exit, $xsig, $name )\n";
  # TODO: callback with ( $pid, $exit, $xsig, $name )

  return wantarray ? ( $pid, $exit, $xsig, $status ) : $pid;
}

sub __fpool_reset
{
  # forked process inherits supervisor's sockets to its sibling processes
  for my $phr ( values %POOLS )
    {
    close( $_->{ 'SOCK' } ) for grep { $_->{ 'SOCK' } } values %{ $phr->{ 'PIDS' } };
    }
  close( $SUPER_SOCK ) if $SUPER_SOCK; # nested pool, own supervisor's socket
  $SUPER_SOCK = undef;
  %POOLS    = ();
  return 1;
}

### supervisor API ###########################################################

sub fpool_send_to
{
  my $pool = uc shift; # pool name
  my $pid = shift;

  my $phr  = $POOLS{ $pool }        or return undef;
  my $pr = $phr->{ 'PIDS' }{ $pid } or return undef;
  my $pid_sock = $pr->{ 'SOCK' };

  return undef unless $pid_sock; # the socket connected to the forked worker
  return socketpair_send( $pid_sock, shift() );
}

sub fpool_recv_from
{
  my $pool = uc shift; # pool name
  my $pid = shift;
  my $data = shift;

  boom "expected scalar reference" unless ref( $data ) eq 'SCALAR';
  $$data = undef;

  my $phr  = $POOLS{ $pool } or return undef;
  my $pr = $phr->{ 'PIDS' }{ $pid } or return undef;

  # returns next non-state message, queued by fpool_update_state()
  return 0 unless $pr->{ 'MSG_QUEUE' } and @{ $pr->{ 'MSG_QUEUE' } } > 0;
  $$data = shift @{ $pr->{ 'MSG_QUEUE' } };
  return 1;
}

# returns text report: busy count, forks count and PID => busy state list
# busy state is from the last fpool_update_state() call
sub fpool_stats
{
  my $pool = uc shift; # pool name

  my $phr  = $POOLS{ $pool }        or return undef;
  my $pids = $phr->{ 'PIDS' } || {};

  my $text = "POOL [$pool] busy [" . ( $phr->{ "BUSY_COUNT" } || 0 ) . "] forks [" . ( $phr->{ "FORKS_COUNT" } || 0 ) . "]\n";
  for my $pid ( sort { $a <=> $b } keys %$pids )
    {
    $text .= "  $pid => " . ( $pids->{ $pid }{ 'BUSY' } ? '*' : '-' ) . "\n";
    }

  return $text;
}

# reads all pending messages, up to 8 per call, from each ready forked process
# socket of the pool (non-blocking), the rest are delayed to the next call of
# fpool_update_state().
# on EOF the socket is removed from the poll set (closed when reaped).
# updates per-process busy state, BUSY is 1 or 0,
# from "STATE:*" (busy) / "STATE:-" (idle)
# other messages are kept in $POOLS{ $pool }{ 'PIDS' }{ $pid }{ 'MSG_QUEUE' },
# up to $MSG_QUEUE_MAX (0 = no limit), see fpool_recv_from()
# returns the new $POOLS{ $pool }{ 'BUSY_COUNT' } or undef if no such pool
sub fpool_update_state
{
  my $pool = uc shift; # pool name

  my $phr  = $POOLS{ $pool }        or return undef;
  my $poll = $phr->{ 'IO::POLL' }   or return 0;

  my $msg;
  $poll->poll( 0 ); # do not wait
  for my $fh ( $poll->handles( POLLIN | POLLHUP | POLLERR ) )
    {
    my $pid = $phr->{ 'FH_PID_MAP' }{ $fh };
    my $pr  = $pid ? $phr->{ 'PIDS' }{ $pid } : undef;
    if( ! $pr )
      {
      $poll->remove( $fh ); # forked process already reaped
      next;
      }

    my $mrl = 8; # message read limit
    my $res;
    while( $mrl-- > 0 )
      {
      $res = socketpair_recv( $fh, \$msg );
      if( ! defined $res )
        {
        # undef is a hard error (EOF, worker closed its socket), stop polling it,
        # otherwise poll() keeps returning it as ready, socket is closed when the
        # worker is reaped. 0 with any $SOCK_ERR is temporary, the socket is kept
        $poll->remove( $fh );
        last;
        }
      # oversized message was discarded by socketpair_recv(), read the next one
      next if $res == 0 and $SOCK_ERR == SOCK_E_TOOBIG;
      last unless $res == 1;

      if( $msg =~ /^STATE:([*-])\z/ )
        {
        $pr->{ 'BUSY' } = $1 eq '*' ? 1 : 0;
        }
      else
        {
        # queue full, discard oldest messages to make room for the new one
        while( $MSG_QUEUE_MAX > 0 and $pr->{ 'MSG_QUEUE' } and @{ $pr->{ 'MSG_QUEUE' } } >= $MSG_QUEUE_MAX )
          {
          shift @{ $pr->{ 'MSG_QUEUE' } };
          $pr->{ 'MSG_DROPPED' }++;
          }
        push @{ $pr->{ 'MSG_QUEUE' } }, $msg;
        }
      }
    }

  # count from the map, so repeated states and reaped processes are not counted
  $phr->{ 'BUSY_COUNT' } = grep { $_->{ 'BUSY' } } values %{ $phr->{ 'PIDS' } };

  return $phr->{ 'BUSY_COUNT' };
}

sub fpool_signal_all
{
  my $pool = uc shift; # pool name
  my $sig  = shift // return undef;

  my $phr  = $POOLS{ $pool }        or return undef;
  return undef unless $phr->{ 'PGRP' };

  kill( $sig, - $phr->{ 'PGRP' } );
}

sub fpool_stop_all
{
  return fpool_signal_all( shift(), 'TERM' );
}

sub fpool_kill_all
{
  return fpool_signal_all( shift(), 'KILL' );
}

sub fpool_count
{
  my $pool = uc shift; # pool name

  my $phr  = $POOLS{ $pool }        or return undef;
  return $phr->{ 'FORKS_COUNT' };
}

sub fpool_busy_count
{
  my $pool = uc shift; # pool name

  my $phr  = $POOLS{ $pool }        or return undef;
  return $phr->{ 'BUSY_COUNT' };
}

### forked sub API ###########################################################

sub fpool_send_super
{
  return undef unless $SUPER_SOCK; # the socket connected to the supervisor
  return socketpair_send( $SUPER_SOCK, shift() );
}

sub fpool_recv_super
{
  return undef unless $SUPER_SOCK; # the socket connected to the supervisor
  return socketpair_recv( $SUPER_SOCK, shift() );
}

sub fpool_iam_busy
{
  fpool_send_super( 'STATE:*' );
}

sub fpool_iam_idle
{
  fpool_send_super( 'STATE:-' );
}

##############################################################################
1;


=pod

=head1 NAME

Data::Tools::Process::ForkPool - pools of forked processes with messaging

=head1 SYNOPSIS

  use Data::Tools::Process::ForkPool;
  use Time::HiRes qw( sleep );

  # supervisor main loop
  while( ! $STOP )
    {
    # reap exited, read states, keep 2..16 workers, grow by 2 when all busy
    fpool_manage( 'WORKERS', \&worker, 2, 16, 2, @worker_args );

    for my $pid ( @pids_of_interest )
      {
      my $msg;
      while( fpool_recv_from( 'WORKERS', $pid, \$msg ) )
        {
        # one message from $pid in $msg
        }
      }
    sleep( 0.1 );
    }
  fpool_stop_all( 'WORKERS' );
  fpool_wait_all( 'WORKERS', 5 ); # wait up to 5 seconds for all to exit

  # forked worker
  sub worker
  {
    $SIG{ 'TERM' } = 'DEFAULT';
    fpool_iam_idle();
    while( 1 )
      {
      my $job;
      my $res = fpool_recv_super( \$job );
      return 0 unless defined $res; # supervisor gone
      if( ! $res ) { sleep( 0.1 ); next } # nothing yet
      fpool_iam_busy();
      fpool_send_super( "done: $job" );
      fpool_iam_idle();
      }
  }

=head1 DESCRIPTION

A fork pool is a named set of forked processes running the same sub. The
supervisor keeps the pool between a minimum and a maximum count and grows
it when all forked processes report busy. Each forked process is connected
to the supervisor by its own L<Net::Tools::Socket::Pair> socket, used for
messages both ways and for the busy/idle state.

Pool names are case insensitive (upper cased). There may be many pools in
one supervisor, and a forked process may run its own (nested) pools.

All forked processes of a pool are placed in the pool's own process group,
which is used to reap and signal them. See the NOTES below and at the top
of the module source for the rules this implies (no setpgrp() or setsid()
in forked processes, no other fork()/wait() code in the supervisor, no
$SIG{ 'CHLD' } = 'IGNORE', signals are not propagated, etc.).

All functions are exported by default. Functions return undef on errors
like an unknown pool or pid. They do not set or clear C<$SOCK_ERR>; it is
set only by the L<Net::Tools::Socket::Pair> calls they make, so check it
only after a socket call result (0 or undef from send/recv).

=head1 MESSAGES

Messages are byte strings up to C<$Net::Tools::Socket::Pair::MSG_MAX>
(128 KiB) long, sent and received whole. Data structures must be
serialized first. The messages "STATE:*" and "STATE:-" are reserved for
fpool_iam_busy() and fpool_iam_idle().

Messages from forked processes are read by fpool_update_state() (called by
fpool_manage()) into a per-process queue, from which fpool_recv_from()
returns them. Messages to forked processes are read directly by
fpool_recv_super().

$Data::Tools::Process::ForkPool::MSG_QUEUE_MAX limits each queue, 0 (the
default) means no limit. When a queue is full, its oldest messages are
discarded.

=head1 SUPERVISOR FUNCTIONS

=head2 fpool_manage( $pool, \&sub, $min, $max, $step, @args )

Creates the pool if needed, reaps exited processes (fpool_wait_all()),
reads states and messages (fpool_update_state()) and then forks new
processes running C<< \&sub->( @args ) >>:

  * up to $min, at least $step at a time
  * $step more, if all processes are busy and the count is below $max

$min defaults to 0, $max to $min (also when smaller than $min), $step to
int( $max / 10 ) + 1. The count may overshoot $max by up to $step - 1.

Should be called periodically from the supervisor's main loop. Returns the
count of new processes, or undef if \&sub is not a code reference.

=head2 fpool_fork_one( $pool, \&sub, @args )

Forks one process in the pool, creates the pool if needed. Returns the new
pid in the supervisor, undef on error. Use it instead of fpool_manage() for
an own growing policy, with fpool_wait_one(), fpool_update_state(),
fpool_count() and fpool_busy_count().

The forked process never returns from it: it runs C<< \&sub->( @args ) >>
and exits with its return value. If \&sub dies, the error is printed to
STDERR and it exits with 255. exit() runs END blocks and destructors in the
forked process too.

=head2 fpool_wait_all( $pool, $timeout )

Reaps all already exited processes of the pool. Without $timeout (or with
0 or a negative one) it does not block. With $timeout (seconds) it also
waits for the rest to exit, checking once per second, and returns as soon
as the pool is empty or the timeout expires. Returns the count of reaped
processes, undef if none were reaped or there is no such pool. Unread
messages of a reaped process are discarded.

=head2 fpool_wait_one( $pool )

Reaps one already exited process of the pool, does not block. Returns its
pid, or in list context ( $pid, $exit_code, $signal, $status ), where
$status is the raw wait status ($?, with the core dump flag). Returns undef
(empty list) if none exited or there is no such pool.

=head2 fpool_update_state( $pool )

Reads pending messages from the forked processes without waiting, up to 8
per process per call, the rest are read on the next call. "STATE:*" and
"STATE:-" update the busy state of the process, other messages are queued
for fpool_recv_from(). Returns the busy count (0 for a pool which has not
forked yet), or undef if there is no such pool.

=head2 fpool_count( $pool ) / fpool_busy_count( $pool )

Return the count of processes in the pool and how many of them are busy,
as of the last fpool_update_state(). undef if there is no such pool.

=head2 fpool_stats( $pool )

Returns a text report: pool name, busy and process counts and the busy
state ('*' busy, '-' idle) of each pid. undef if there is no such pool.

=head2 fpool_signal_all( $pool, $signal )

Sends $signal ('TERM', 'HUP', 9, etc.) to all processes of the pool (its
process group). Returns the result of kill(), undef if there is no such
pool or it has no processes.

fpool_stop_all( $pool ) sends TERM, fpool_kill_all( $pool ) sends KILL.

=head2 fpool_send_to( $pool, $pid, $data )

Sends message $data to the forked process $pid. Returns the
socketpair_send() result: 1 sent, 0 not sent (queue full, etc.), undef
if the process closed its socket, or undef if there is no such pool or pid.

=head2 fpool_recv_from( $pool, $pid, \$data )

Takes the next queued message from the forked process $pid into $data.
Returns 1 for a message, 0 if the queue is empty, undef if there is no
such pool or pid. $data is set to undef whenever the result is not 1.
Dies (boom) if \$data is not a scalar reference. Messages are queued only
by fpool_update_state() (and fpool_manage()).

=head1 FORKED PROCESS FUNCTIONS

These work only in a process forked by fpool_fork_one() or fpool_manage(),
elsewhere they return undef.

=head2 fpool_send_super( $data )

Sends message $data to the supervisor. Returns the socketpair_send()
result: 1 sent, 0 not sent, undef if the supervisor is gone.

=head2 fpool_recv_super( \$data )

Reads the next message from the supervisor into $data, does not wait.
Returns the socketpair_recv() result: 1 for a message, 0 if nothing is
waiting, undef if the supervisor is gone.

=head2 fpool_iam_busy() / fpool_iam_idle()

Report the busy or idle state to the supervisor, as seen by
fpool_busy_count() and used by fpool_manage() to grow the pool.

=head1 NOTES

=over 4

=item *

Forked processes must not change their process group (setpgrp(), setsid(),
daemonizing), otherwise the pool never reaps or signals them.

=item *

The pools should be the only means of forking in the supervisor. Other code
which calls wait() or waitpid( -1, ... ), and $SIG{ 'CHLD' } = 'IGNORE',
may reap the pool's processes behind its back. system(), qx// and piped
open() are safe.

=item *

Signals are not propagated to the pools. The supervisor must catch the
signals it cares about and call fpool_signal_all(), fpool_stop_all() or
fpool_kill_all() for each pool. Forked processes inherit the supervisor's
%SIG and should set their own handlers first.

=item *

If the supervisor dies without stopping the pools, forked processes keep
running. They see it as undef from fpool_recv_super() or a getppid()
change.

=item *

Messages sent by a forked process right before it exits may be lost when
it is reaped. A process which must deliver a result should wait for an
acknowledge from the supervisor before it returns.

=item *

Inherited DBI handles should have AutoInactiveDestroy set, END blocks meant
for the supervisor only should check $$.

=item *

Works on Linux only, see L<Net::Tools::Socket::Pair>.

=back

=head1 SEE ALSO

L<Net::Tools::Socket::Pair>, L<Net::Tools::Socket::Err>,
L<Data::Tools::Process::Forks>

=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"
        <cade@noxrun.com>
  http://cade.noxrun.com/

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Vladi Belperchinov-Shabanski "Cade"

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

=cut
