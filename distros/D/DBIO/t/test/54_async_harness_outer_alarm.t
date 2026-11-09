use strict;
use warnings;
use Test::More;
use POSIX ();
use Time::HiRes ();

use DBIO::Test::Future ();
use DBIO::Test::AsyncHarness;

# An alarm set outside DBIO::Test::AsyncHarness::await is still set after it
# (karr k300).
#
# A process has ONE alarm. await guards its wait with it -- `alarm $timeout`,
# and `alarm 0` on the way out -- so it took whatever alarm was running off
# the clock for good: a live test file that guards itself against a hang with
# `alarm 120` lost that guard at its first await (warm_pool is a row of them)
# and ran unguarded from there. An await called from a callback inside another
# await did the same to that one's timeout.
#
# The claim: await borrows the alarm and gives it back. An alarm that was
# running when await was entered
#   - is running when await is left, on every way out -- the Future done or
#     failed, a die in _tick_loop, await's own timeout -- and is due when it
#     was due: not started over, and not rounded to a whole second;
#   - fires at its own time, under the handler it was set with, when that
#     time comes before await's timeout -- as itself, not as a "TIMEOUT
#     awaiting Future"; a handler that returns leaves await's timeout in force;
#   - fires as soon as await is left, when its time came while await had it
#     off the clock.
# With no alarm running nothing is left set, as before. Awaits inside one
# another keep each other's.
#
# OFFLINE: a harness subclass whose "loop" is a short sleep, DBIO::Test::Future
# for the Futures. No connection.
#
# Times are compared as intervals -- "due no earlier than, no later than" --
# with $SLACK around them, so a machine that is slow to schedule this process
# does not fail the file; what the claim excludes is off by 0.3s and more.
#
# This file cannot guard itself with an alarm: the alarm is what it tests. A
# child process ends it if it hangs, and every wait is bounded in turns.

my $TEST_PID = $$;
my $watchdog = fork;
plan skip_all => "cannot fork a watchdog: $!" unless defined $watchdog;
unless ($watchdog) {
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

{
  package K300::Harness;
  use base 'DBIO::Test::AsyncHarness';

  # One turn of the loop: a short sleep, which an alarm cuts short, then
  # whatever the case wants to happen on that turn. A wait that does not end
  # dies after {most_ticks} turns instead of hanging.
  sub _tick_loop {
    my ($self) = @_;
    die "the wait did not end: $self->{most_ticks} turns\n"
      if ++$self->{ticks} > $self->{most_ticks};
    Time::HiRes::sleep($self->{tick});
    $self->{on_tick}->($self) if $self->{on_tick};
    return;
  }
}

sub harness {
  my (%set) = @_;
  return bless { timeout => 5, tick => 0.01, most_ticks => 150, ticks => 0, %set },
    'K300::Harness';
}

# A Future that is never done, and one that is done after $turns more turns
# of $h's loop.
sub never { DBIO::Test::Future->new }
sub done_after {
  my ($h, $turns, $value) = @_;
  my $f     = DBIO::Test::Future->new;
  my $at    = $h->{ticks} + $turns;
  my $other = $h->{on_tick};
  $h->{on_tick} = sub {
    $other->(@_) if $other;
    $f->done($value) if $_[0]->{ticks} == $at;
  };
  return $f;
}

my $SLACK = 0.1;
sub now { Time::HiRes::time() }

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

sub wait_for {
  my ($cond, $most) = @_;
  my $until = now() + $most;
  Time::HiRes::sleep(0.01) until $cond->() || now() >= $until;
  return;
}

sub death_of (&) {
  my ($code) = @_;
  local $@;
  return eval { $code->(); 1 } ? '(it returned)' : "$@";
}

# --- 1. the card: an alarm set before await fires after it ---------------------
#
# await's timeout comes first and is not reached; the alarm is back afterwards
# and fires when it was due, under the handler it was set with.
{
  my $l = 'an alarm due after the timeout of an await that returns';
  my $h = harness(timeout => 1);
  my $fired;
  local $SIG{ALRM} = sub { $fired = now() };
  my $want = arm(1.2);

  is $h->await(done_after($h, 40, 'value')), 'value', "$l: await returns the value";
  is_due(due(), $want, "$l: it is still running, due when it was due");

  wait_for(sub { defined $fired }, 3);
  disarm();
  ok defined $fired, "$l: ... and it fires, under the handler it was set with";
  ok defined $fired && $fired >= $want->[0] - $SLACK, "$l: ... not before it was due";
}

# ... set with perl's own alarm, as a test file sets it, in whole seconds: what
# is left of it is not rounded to a second when it is put back.
{
  my $l = 'an alarm set with the builtin alarm';
  my $h = harness(timeout => 1);
  local $SIG{ALRM} = sub { };
  my $want = arm(3, 'builtin');
  is $h->await(done_after($h, 25, 'value')), 'value', "$l: await returns the value";
  is_due(due(), $want, "$l: it is still running, due when it was due");
  disarm();
}

# ... and the alarm that is due BEFORE await's timeout is still running after
# an await that returned before either.
{
  my $l = 'an alarm due before the timeout of an await that returns';
  my $h = harness(timeout => 5);
  local $SIG{ALRM} = sub { };
  my $want = arm(2);
  is $h->await(done_after($h, 5, 'value')), 'value', "$l: await returns the value";
  is_due(due(), $want, "$l: it is still running, due when it was due");
  disarm();
}

# --- 2. the outer alarm is due first: it fires, as itself ----------------------
#
# The Future is never done. What ends the wait is the outer alarm at its time,
# under its own handler -- not the harness with a "TIMEOUT awaiting Future".
{
  my $l = 'an alarm due before the timeout, the Future never done';
  my $h = harness(timeout => 5);
  local $SIG{ALRM} = sub { die "the file's own alarm\n" };
  my $want = arm(0.3);

  my $death = death_of { $h->await(never()) };
  my $at    = now();
  like $death, qr/^the file's own alarm$/m, "$l: its own handler ends the wait";
  unlike $death, qr/TIMEOUT awaiting Future/, "$l: ... not the harness's timeout";
  ok $at >= $want->[0] - $SLACK && $at < $want->[1] + 1, "$l: ... when it was due"
    or diag sprintf 'ended %.3fs after it was due', $at - $want->[0];
  is due(), undef, "$l: it has fired: no alarm is running afterwards";
  disarm();
}

# Its handler returns instead of dying: the wait goes on, and await's timeout
# is still what it was -- counted from when await was entered, not from here.
{
  my $l = 'an alarm due before the timeout whose handler returns';
  my $h = harness(timeout => 0.6);
  my ($ran, $then) = (0);
  local $SIG{ALRM} = sub { $ran++ };
  $h->{on_tick} = sub { $then ||= due() if $ran };
  arm(0.2);

  my $entered = now();
  my $death   = death_of { $h->await(never()) };
  is $ran, 1, "$l: it fired, once, under its own handler";
  like $death, qr/TIMEOUT awaiting Future in K300::Harness/,
    "$l: ... and the wait ended on the harness's timeout";
  is_due($then, [ $entered + 0.6, $entered + 0.6 ],
    "$l: ... due when it was due from the start");
  is due(), undef, "$l: no alarm is running afterwards";
  disarm();
}

# It has no handler at all -- the form `alarm 120;` and nothing else: the
# signal ends the process, as it would have without the harness.
{
  my $l = 'an alarm with no handler, due before the timeout';
  my $pid = fork;
  if (defined $pid && !$pid) {
    $SIG{ALRM} = 'DEFAULT';
    Time::HiRes::alarm(0.3);
    eval { harness(timeout => 5)->await(never()) };
    POSIX::_exit(42);
  }
  SKIP: {
    skip "cannot fork: $!", 1 unless defined $pid;
    waitpid $pid, 0;
    is $? & 127, POSIX::SIGALRM(), "$l: ends the process with SIGALRM"
      or diag sprintf 'wait status %d (exit %d, signal %d)', $?, $? >> 8, $? & 127;
  }
}

# --- 3. await's timeout is due first: TIMEOUT, and the outer alarm is back -----
{
  my $l = 'an alarm due after the timeout, the Future never done';
  my $h = harness(timeout => 1);
  my $fired = 0;
  local $SIG{ALRM} = sub { $fired++ };
  my $want = arm(4);

  like death_of { $h->await(never()) }, qr/TIMEOUT awaiting Future in K300::Harness/,
    "$l: the wait ends on the harness's timeout";
  is $fired, 0, "$l: the outer handler has not run";
  is_due(due(), $want, "$l: the alarm is still running, due when it was due");
  disarm();
}

# --- 4. no outer alarm: nothing is left running, as before ---------------------
{
  my $h = harness(timeout => 1);
  is $h->await(done_after($h, 3, 'value')), 'value', 'no alarm running: await returns the value';
  is due(), undef, 'no alarm running: none is running after an await that returned';

  # A timeout below one second is one: the builtin alarm made it `alarm 0`,
  # no timeout at all.
  $h = harness(timeout => 0.3);
  like death_of { $h->await(never()) }, qr/TIMEOUT awaiting Future/,
    'no alarm running: a timeout of 0.3s ends the wait';
  is due(), undef, 'no alarm running: none is running after an await that timed out';

  # ... and no timeout stays no timeout: await sets no alarm of its own, and
  # leaves one that is running alone.
  my @on_clock;
  $h = harness(timeout => 0, on_tick => sub { push @on_clock, due() });
  is $h->await(done_after($h, 5, 'value')), 'value', 'timeout 0: await waits without a timeout';
  is_deeply \@on_clock, [ (undef) x 5 ], 'timeout 0: ... and sets no alarm';

  local $SIG{ALRM} = sub { };
  my $want = arm(3);
  $h = harness(timeout => 0);
  is $h->await(done_after($h, 5, 'value')), 'value', 'timeout 0, an alarm running: await returns the value';
  is_due(due(), $want, 'timeout 0, an alarm running: it is still running, due when it was due');
  disarm();

  # With no timeout an alarm that is running is the only thing to end a wait
  # that does not end -- and does.
  local $SIG{ALRM} = sub { die "the file's own alarm\n" };
  arm(0.3);
  $h = harness(timeout => 0);
  like death_of { $h->await(never()) }, qr/^the file's own alarm$/m,
    'timeout 0, an alarm running, the Future never done: the alarm ends the wait';
  disarm();
}

# --- 5. await dies in _tick_loop: the outer alarm is back ----------------------
#
# With no outer alarm, none is running: await's own does not outlive it.
{
  my $h = harness(timeout => 2, on_tick => sub { die "the loop broke\n" if $_[0]->{ticks} == 5 });
  like death_of { $h->await(never()) }, qr/^the loop broke$/m,
    'no alarm running, _tick_loop dies: await dies with that';
  is due(), undef, 'no alarm running, _tick_loop dies: none is running afterwards';
  disarm();
}

# With one, whichever of the two is due first.
for my $case ([ 'due after the timeout', 4 ], [ 'due before the timeout', 1.5 ]) {
  my ($which, $seconds) = @$case;
  my $l = "an alarm $which, _tick_loop dies";
  my $h = harness(timeout => 2, on_tick => sub { die "the loop broke\n" if $_[0]->{ticks} == 5 });
  my $fired = 0;
  local $SIG{ALRM} = sub { $fired++ };
  my $want = arm($seconds);

  like death_of { $h->await(never()) }, qr/^the loop broke$/m, "$l: await dies with that";
  is $fired, 0, "$l: the outer handler has not run";
  is_due(due(), $want, "$l: the alarm is still running, due when it was due");
  disarm();
}

# --- 6. awaits inside one another ---------------------------------------------
#
# A callback of the outer await's loop awaits something itself. The inner
# await finds the outer one's alarm running and gives it back like any other:
# the outer await still has its timeout, and the file its alarm.
for my $case ([ 'a longer timeout', 5 ], [ 'a shorter timeout', 2 ]) {
  my ($which, $inner_timeout) = @$case;
  my $l = "an await inside another, with $which";
  my $outer = harness(timeout => 3);
  my $inner = harness(timeout => $inner_timeout);
  local $SIG{ALRM} = sub { };
  my $file = arm(8);

  my $f = DBIO::Test::Future->new;
  my ($inner_value, $then);
  $outer->{on_tick} = sub {
    return unless $_[0]->{ticks} == 3;
    $inner_value = $inner->await(done_after($inner, 5, 'inner value'));
    $then = due();
    $f->done('outer value');
  };

  my $entered = now();
  is $outer->await($f), 'outer value', "$l: the outer await returns its value";
  is $inner_value, 'inner value', "$l: ... the inner one its own";
  is_due($then, [ $entered + 3, $entered + 3 ],
    "$l: after the inner await the outer one's timeout is still running, due when it was due");
  is_due(due(), $file, "$l: after both the file's alarm is still running, due when it was due");
  disarm();
}

# The inner await times out: the outer one still has its timeout.
{
  my $l = 'an await inside another that times out';
  my $outer = harness(timeout => 3);
  my $inner = harness(timeout => 0.3);
  local $SIG{ALRM} = sub { };
  my $file = arm(8);

  my $f = DBIO::Test::Future->new;
  my ($inner_death, $then);
  $outer->{on_tick} = sub {
    return unless $_[0]->{ticks} == 3;
    $inner_death = death_of { $inner->await(never()) };
    $then = due();
    $f->done('outer value');
  };

  my $entered = now();
  is $outer->await($f), 'outer value', "$l: the outer await returns its value";
  like $inner_death, qr/TIMEOUT awaiting Future/, "$l: ... the inner one timed out";
  is_due($then, [ $entered + 3, $entered + 3 ],
    "$l: the outer one's timeout is still running, due when it was due");
  is_due(due(), $file, "$l: the file's alarm is still running, due when it was due");
  disarm();
}

# The outer await's timeout comes while the inner one waits, with a longer
# timeout of its own: it is the outer one's that ends both.
{
  my $l = 'an await whose timeout comes during an await inside it';
  my $outer = harness(timeout => 0.4);
  my $inner = harness(timeout => 5);
  local $SIG{ALRM} = sub { };
  my $file = arm(8);

  $outer->{on_tick} = sub { $inner->await(never()) };
  my $entered = now();
  my $death   = death_of { $outer->await(never()) };
  my $took    = now() - $entered;
  like $death, qr/TIMEOUT awaiting Future in K300::Harness/, "$l: the wait ends on a harness timeout";
  ok $took >= 0.4 - $SLACK && $took < 1.4, "$l: ... the outer one's, at its time"
    or diag sprintf 'after %.3fs', $took;
  is_due(due(), $file, "$l: the file's alarm is still running, due when it was due");
  disarm();
}

# --- 7. the outer alarm comes due while await has it off the clock --------------
#
# await's timeout is due first, so the outer alarm is off the clock; a
# callback swallows the timeout and stays in the loop past the outer alarm's
# time. That alarm is not lost: it fires once await is left, under its own
# handler.
{
  my $l = 'an alarm that came due while await had it off the clock';
  my $fired = 0;
  local $SIG{ALRM} = sub { $fired++ };
  my $h = harness(timeout => 0.2, on_tick => sub {
    my $until = now() + 0.6;
    eval { Time::HiRes::sleep(0.05) } while now() < $until;
    die "the loop broke late\n";
  });
  arm(0.4);

  like death_of { $h->await(never()) }, qr/^the loop broke late$/m, "$l: await dies with the loop's error";
  wait_for(sub { $fired }, 1);
  is $fired, 1, "$l: it fires once await is left, under its own handler";
  is due(), undef, "$l: ... and no alarm is running then";
  disarm();
}

# --- 8. many awaits do not move it ---------------------------------------------
#
# What is left of the outer alarm is not rounded to a whole second as it is
# put back -- perl's own alarm answers 9.8 left as 10: awaits that follow one
# another quickly would push the alarm ahead of them for good, and the file's
# guard would never fire.
for my $case ([ 'due before the timeout', 30 ], [ 'due after the timeout', 10 ]) {
  my ($which, $timeout) = @$case;
  my $l = "an alarm $which, 150 awaits in a row";
  my $h = harness(timeout => $timeout, tick => 0.002, most_ticks => 1000);
  local $SIG{ALRM} = sub { };
  my $want = arm(20);

  my $returned = 0;
  for (1 .. 150) {
    my $f = DBIO::Test::Future->new;
    $h->{on_tick} = sub { $f->done('value') };
    $returned++ if $h->await($f) eq 'value';
  }
  is $returned, 150, "$l: each returns its value";
  is_due(due(), $want, "$l: it is still due when it was due");
  disarm();
}

done_testing;
