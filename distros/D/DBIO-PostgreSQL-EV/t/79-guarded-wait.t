use strict;
use warnings;
use Test::More;
use POSIX ();
use Time::HiRes ();

use EV;
use Future;
use FindBin;
use lib "$FindBin::Bin/lib";
use GuardedWait;

# A wait guarded through t/lib/GuardedWait.pm gives the process alarm back
# (karr k88).
#
# A process has ONE alarm. Nine live files of this distribution each carried a
# copy of
#
#   sub await_guarded {
#     my ($f, $what) = @_;
#     local $SIG{ALRM} = sub { die "TIMEOUT awaiting $what\n" };
#     alarm 15;
#     EV::run(EV::RUN_ONCE) until $f->is_ready;
#     alarm 0;
#     return $f;
#   }
#
# and `alarm 0` clears whatever alarm was running: a file that guards itself
# against a hang with `alarm 120` would have lost that guard at its first
# guarded wait, so none of the nine had one -- and everything in them outside
# such a wait (a blocking ->get, setup, teardown, a bare EV::run) was guarded
# by nothing. A guarded wait inside another took that one's timeout the same
# way. The cause is core's k300.
#
# The claim: GuardedWait borrows the alarm. An alarm that is running when
# until_ready or run is entered
#   - is running when it is left, on every way out -- the Future done or
#     failed, a die out of the wait, the wait's own timeout -- and is due when
#     it was due: not started over, not rounded to a whole second;
#   - fires at its own time, as itself, when that comes before the wait's
#     timeout: under its handler, or ending the process where it has none --
#     the `alarm 120;` of a test file.
# The wait's own timeout still ends it, with the caller's message, word for
# word. With no alarm running none is left set. Waits inside one another keep
# each other's.
#
# OFFLINE: Futures settled by EV timers. No EV::Pg, no connection, no skip.
#
# Times are compared as intervals with $SLACK around them, so a machine that
# is slow to schedule this process does not fail the file; what the claim
# excludes is off by a second and more, or no alarm at all.
#
# This file cannot guard itself with an alarm: the alarm is what it tests. A
# child process ends it if it hangs, and every Future that is "never" done
# fails by a timer of its own, so that a wait nothing ended shows as a failed
# claim, not as a hang.

my $TEST_PID = $$;
my $watchdog = fork;
diag "no watchdog for this file: fork: $!" unless defined $watchdog;
if (defined $watchdog && !$watchdog) {
  for (1 .. 90) {
    sleep 1;
    POSIX::_exit(0) unless getppid() == $TEST_PID;
  }
  print STDERR "# $0: still running after 90s, killed by its watchdog\n";
  kill KILL => $TEST_PID;
  POSIX::_exit(0);
}
END {
  if ($watchdog && $$ == $TEST_PID) {
    my $status = $?;
    kill TERM => $watchdog;
    waitpid $watchdog, 0;
    $? = $status;
  }
}

my $SLACK = 0.15;
sub now { Time::HiRes::time() }

# The timers of the case that is running; quiet() stops them, so that none
# wakes the loop of the next case.
my @TIMERS;
sub after {
  my ($seconds, $code) = @_;
  EV::now_update();
  push @TIMERS, EV::timer($seconds, 0, $code);
  return;
}
sub quiet { @TIMERS = (); return }

# A Future done, or failed, $seconds from now.
sub done_in {
  my ($seconds, @value) = @_;
  my $f = Future->new;
  after($seconds, sub { $f->done(@value) });
  return $f;
}
sub failed_in {
  my ($seconds, $error) = @_;
  my $f = Future->new;
  after($seconds, sub { $f->fail($error) });
  return $f;
}

# A Future nothing settles -- except this file, $bound seconds from now, with
# a failure: a wait that outlives what should have ended it returns then.
sub never { failed_in($_[0], "nothing ended this wait in $_[0]s\n") }

# Not a Future: a wait on it dies at the third look.
{
  package K88::Breaks;
  sub new      { return bless { looks => 0 }, $_[0] }
  sub is_ready { die "the wait broke\n" if ++$_[0]{looks} > 2; return 0 }
}

# Set the process alarm; says when it is due, as [ no earlier, no later ].
# 'builtin' sets it the way a test file does, with perl's own alarm.
sub arm {
  my ($seconds, $how) = @_;
  my $before = now();
  if ($how) { alarm $seconds } else { Time::HiRes::alarm($seconds) }
  return [ $before + $seconds, now() + $seconds ];
}

# When the alarm that is running is due, in the same form; undef when none
# is. Read by taking it off the clock and putting it back at once.
sub due {
  my $before = now();
  my $left   = Time::HiRes::alarm(0) or return undef;
  Time::HiRes::alarm($left);
  return [ $before + $left, now() + $left ];
}

sub disarm { Time::HiRes::alarm(0); return }

sub is_due {
  my ($got, $want, $name) = @_;
  my $same = $got
    && $got->[0] <= $want->[1] + $SLACK
    && $got->[1] >= $want->[0] - $SLACK;
  ok($same, $name) or diag $got
    ? sprintf('due %.3fs %s than it was', abs($got->[0] - $want->[0]),
        ($got->[0] > $want->[0] ? 'later' : 'earlier'))
    : 'no alarm is running';
  return;
}

sub death_of (&) {
  my ($code) = @_;
  local $@;
  return eval { $code->(); 1 } ? '(it returned)' : "$@";
}

# The message a test file hands over: what it waited for, and the regression
# the wait guards against.
my $MESSAGE = "TIMEOUT awaiting the answer (karr k00 regression: it hung)\n";

# --- 1. the Future is done: the alarm is still running -------------------------
{
  my $l = 'an alarm running, the Future done';
  my $fired = 0;
  local $SIG{ALRM} = sub { $fired++ };
  my $want = arm(3);

  my $f   = done_in(0.2, 'value');
  my $got = GuardedWait->until_ready($f, 2, $MESSAGE);
  is $got, $f, "$l: until_ready returns the Future it was given";
  is_deeply [ $f->get ], ['value'], "$l: ... done, with its value";
  is_due(due(), $want, "$l: the alarm is still running, due when it was due");
  is $fired, 0, "$l: ... and has not fired";
  disarm();
  quiet();
}

# ... set the way a test file sets it, with perl's own alarm in whole seconds:
# what is left of it is not rounded to a second when it is put back.
{
  my $l = 'an alarm set with the builtin alarm, the Future done';
  local $SIG{ALRM} = sub { };
  my $want = arm(3, 'builtin');
  GuardedWait->until_ready(done_in(0.3), 2, $MESSAGE);
  is_due(due(), $want, "$l: it is still running, due when it was due");
  disarm();
  quiet();
}

# --- 2. the Future failed: it is handed back, not thrown -----------------------
#
# The files assert on the failed Future -- is_failed, its message -- so a wait
# that ends on one returns it like any other.
{
  my $l = 'an alarm running, the Future failed';
  local $SIG{ALRM} = sub { };
  my $want = arm(3);

  my $f = failed_in(0.1, "the statement failed\n");
  is death_of { GuardedWait->until_ready($f, 2, $MESSAGE) }, '(it returned)',
    "$l: until_ready returns";
  ok $f->is_failed, "$l: ... the Future failed";
  is scalar $f->failure, "the statement failed\n", "$l: ... with its own error";
  is_due(due(), $want, "$l: the alarm is still running, due when it was due");
  disarm();
  quiet();
}

# --- 3. a die out of the wait: the alarm is still running ----------------------
{
  my $l = 'an alarm running, the wait dies';
  my $fired = 0;
  local $SIG{ALRM} = sub { $fired++ };
  my $want = arm(3);

  is death_of { GuardedWait->until_ready(K88::Breaks->new, 2, $MESSAGE) }, "the wait broke\n",
    "$l: until_ready dies with that error, as it was";
  is_due(due(), $want, "$l: the alarm is still running, due when it was due");
  is $fired, 0, "$l: ... and has not fired";
  disarm();
  quiet();
}

# --- 4. the wait's timeout: the caller's message, and the alarm is back --------
{
  my $l = 'an alarm due after the timeout, the Future never done';
  my $fired = 0;
  local $SIG{ALRM} = sub { $fired++ };
  my $want = arm(5);

  my $entered = now();
  my $death   = death_of { GuardedWait->until_ready(never(3), 1, $MESSAGE) };
  my $took    = now() - $entered;
  is $death, $MESSAGE, "$l: the wait ends with the caller's message, word for word";
  ok $took >= 1 - $SLACK && $took < 2, "$l: ... after its timeout"
    or diag sprintf 'after %.3fs', $took;
  is $fired, 0, "$l: the outer handler has not run";
  is_due(due(), $want, "$l: the alarm is still running, due when it was due");
  disarm();
  quiet();
}

# --- 5. no alarm running: none is left running ---------------------------------
{
  GuardedWait->until_ready(done_in(0.1), 2, $MESSAGE);
  is due(), undef, 'no alarm running: none is running after a wait that returned';
  quiet();

  is death_of { GuardedWait->until_ready(K88::Breaks->new, 2, $MESSAGE) }, "the wait broke\n",
    'no alarm running: a wait that dies';
  is due(), undef, 'no alarm running: ... leaves none running';

  is death_of { GuardedWait->until_ready(never(3), 1, $MESSAGE) }, $MESSAGE,
    'no alarm running: a wait that times out';
  is due(), undef, 'no alarm running: ... leaves none running';
  disarm();
  quiet();
}

# --- 6. the outer alarm is due first: it fires, as itself ----------------------
#
# What ends the wait is the alarm that was running, at its time and under its
# own handler -- not the wait's timeout with the wait's message.
{
  my $l = 'an alarm due before the timeout, the Future never done';
  local $SIG{ALRM} = sub { die "the file's own alarm\n" };
  my $want = arm(0.4);

  my $death = death_of { GuardedWait->until_ready(never(2), 5, $MESSAGE) };
  my $at    = now();
  # Its first line: where the handler runs between two turns of the loop,
  # the error goes out through core's await, which puts a file and line
  # behind it.
  like $death, qr/\Athe file's own alarm\n/, "$l: its own handler ends the wait";
  ok $at >= $want->[0] - $SLACK && $at < $want->[1] + 1, "$l: ... when it was due"
    or diag sprintf 'ended %.3fs after it was due', $at - $want->[0];
  disarm();
  quiet();
}

# It has no handler -- `alarm 120;` and nothing else, as the test files have
# it: the signal ends the process.
{
  my $l = 'an alarm with no handler, due before the timeout';
  my $pid = fork;
  if (defined $pid && !$pid) {
    $SIG{ALRM} = 'DEFAULT';
    Time::HiRes::alarm(0.4);
    eval { GuardedWait->until_ready(never(2), 5, $MESSAGE) };
    POSIX::_exit(42);
  }
  if (defined $pid) {
    waitpid $pid, 0;
    is $? & 127, POSIX::SIGALRM(), "$l: ends the process with SIGALRM"
      or diag sprintf 'wait status %d (exit %d, signal %d)', $?, $? >> 8, $? & 127;
  }
  else {
    fail "$l: fork: $!";
  }
  quiet();
}

# --- 7. a guarded wait inside another ------------------------------------------
#
# A callback the outer wait's loop runs waits for something itself, with a
# longer timeout, and returns. The outer wait still has its timeout -- it ends
# on it, with its own message -- and the file its alarm.
{
  my $l = 'a guarded wait inside another';
  local $SIG{ALRM} = sub { };
  my $file = arm(6);

  my $inner;
  after(0.1, sub {
    $inner = death_of { GuardedWait->until_ready(done_in(0.2), 5, "TIMEOUT awaiting the inner one\n") };
  });

  my $entered = now();
  my $death   = death_of { GuardedWait->until_ready(never(3), 1, "TIMEOUT awaiting the outer one\n") };
  my $took    = now() - $entered;
  is $inner, '(it returned)', "$l: the inner wait returns";
  is $death, "TIMEOUT awaiting the outer one\n", "$l: the outer one ends on its own timeout";
  ok $took >= 1 - $SLACK && $took < 2, "$l: ... at its time"
    or diag sprintf 'after %.3fs', $took;
  is_due(due(), $file, "$l: after both the file's alarm is still running, due when it was due");
  disarm();
  quiet();
}

# --- 8. many waits do not move it ----------------------------------------------
#
# A file is a row of quick waits. What is left of its alarm is not rounded up
# to a whole second each time it is put back -- that would push the alarm
# ahead of the row for good.
{
  my $l = 'an alarm set with the builtin alarm, 100 waits in a row';
  local $SIG{ALRM} = sub { };
  my $want = arm(20, 'builtin');

  my $returned = 0;
  for my $n (1 .. 100) {
    my $f = $n % 10 ? Future->done('value') : done_in(0.002, 'value');
    $returned++ if GuardedWait->until_ready($f, 15, $MESSAGE)->get eq 'value';
  }
  is $returned, 100, "$l: each returns its Future";
  is_due(due(), $want, "$l: it is still due when it was due");
  disarm();
  quiet();
}

# --- 9. run: a blocking call under the same guard -------------------------------
#
# What has no Future to wait for -- the blocking txn_do of t/44 -- is called
# under the timeout instead.
{
  my $l = 'an alarm running, a call';
  my $fired = 0;
  local $SIG{ALRM} = sub { $fired++ };
  my $want = arm(5);

  my $ran = 0;
  is death_of { GuardedWait->run(sub { $ran++ }, 2, $MESSAGE) }, '(it returned)',
    "$l that returns: run returns";
  is $ran, 1, "$l that returns: ... having called it once";
  is_due(due(), $want, "$l that returns: the alarm is still running, due when it was due");

  is death_of { GuardedWait->run(sub { die "the call died\n" }, 2, $MESSAGE) }, "the call died\n",
    "$l that dies: run dies with that error, as it was";
  is_due(due(), $want, "$l that dies: the alarm is still running, due when it was due");

  my $entered = now();
  my $death   = death_of {
    GuardedWait->run(sub { my $until = now() + 3; Time::HiRes::sleep(0.05) while now() < $until }, 1, $MESSAGE);
  };
  my $took = now() - $entered;
  is $death, $MESSAGE, "$l that blocks: run ends it with the caller's message";
  ok $took >= 1 - $SLACK && $took < 2, "$l that blocks: ... after its timeout"
    or diag sprintf 'after %.3fs', $took;
  is $fired, 0, "$l: the outer handler has not run";
  is_due(due(), $want, "$l that blocks: the alarm is still running, due when it was due");
  disarm();
}

# --- 10. no timeout is no guard -------------------------------------------------
#
# A wait without a timeout is the unguarded wait this helper is there to
# replace: refused before anything is waited for.
for my $case ([ 'no timeout', undef ], [ 'a timeout of 0', 0 ], [ 'a negative timeout', -1 ]) {
  my ($which, $seconds) = @$case;
  my $ran = 0;
  like death_of { GuardedWait->until_ready(Future->new, $seconds, $MESSAGE) },
    qr/^GuardedWait: a wait needs a timeout in seconds/, "$which: until_ready refuses";
  like death_of { GuardedWait->run(sub { $ran++ }, $seconds, $MESSAGE) },
    qr/^GuardedWait: a wait needs a timeout in seconds/, "$which: run refuses";
  is $ran, 0, "$which: ... and calls nothing";
}

is due(), undef, 'no alarm is left running at the end of this file';

done_testing;
