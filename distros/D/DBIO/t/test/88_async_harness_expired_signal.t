use strict;
use warnings;
use Test::More;
use POSIX ();
use Time::HiRes ();

BEGIN {
  my $hires = do { local $@; eval { Time::HiRes::alarm(0); 1 } };
  plan skip_all => 'Time::HiRes::alarm is not implemented on this platform: no alarm in fractions of a second'
    unless $hires;
}

# Where the kernel timers run slower than the clock this measures it and makes
# Time::HiRes::sleep and ::alarm keep the clock again (the mock below sets the
# alarm through that), so that the delays mean what they say; beyond a limit it
# skips the file.
use lib 't/lib';
use T::KernelTimers;

use DBIO::Test::Future ();
use DBIO::Test::AsyncHarness;

# The signal of await's own timeout never costs the outer alarm and never
# reaches the process after await has left.
#
# On a host whose kernel reports a timer as expired while its signal is still
# on the way, a loop that spins without a pause ends the wait by the clock in
# the very instant the alarm of await is due. alarm(0) then answers "expired",
# and the signal is delivered afterwards: after await has dropped its handler
# (the default one ends the process) or inside await's own bookkeeping (where
# its handler dies and the outer alarm would never be put back).
#
# The claim:
#   - the clock ends the wait at the timeout, the alarm a short grace later, so
#     a loop that turns is out of await before the alarm is due;
#   - a signal that is late anyway is caught: await waits for it, bounded, and
#     leaves $SIG{ALRM} alone until then; it never dies outside the wait;
#   - the alarm that was running when await was entered is running when it is
#     left;
#   - a loop that hangs in one call past the grace is still cut by the signal.
#
# Simulated on any host by a Time::HiRes::alarm that answers as those systems
# do: alarm(0) on a timer that is due reports 0 left, and the signal follows
# afterwards -- from a child process 0.05s later ('child'), at once, inside the
# call ('sync'), or not at all ('drop'). A real timer, 0.2s later
# than the simulated one, is set beside it, so a loop hanging in a C call still
# gets its signal.
#
# This file cannot guard itself with an alarm: the alarm is what it tests. A
# child process ends it if it hangs, and every loop is bounded in turns.

my $TEST_PID = $$;
my $watchdog = fork;
plan skip_all => "cannot fork a watchdog: $!" unless defined $watchdog;
unless ($watchdog) {
  for (1 .. 60) {
    sleep 1;
    POSIX::_exit(0) unless getppid() == $TEST_PID;
  }
  print STDERR "# $0: still running after 60s, killed by its watchdog\n";
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

our ($MODE, $REAL, $expiry) = ('drop', 1);
my @kids;

BEGIN {
  my $real = \&Time::HiRes::alarm;
  no warnings 'redefine';
  *Time::HiRes::alarm = sub ($;$) {
    my ($secs) = @_;
    my $now     = Time::HiRes::time();
    my $expired = defined $expiry && $now >= $expiry - 0.002;
    my $left    = defined $expiry && !$expired ? $expiry - $now : 0;
    $real->(0);
    $expiry = undef;
    if ($secs > 0) {
      $expiry = $now + $secs;
      $real->($secs + 0.2) if $REAL;
    }
    elsif ($expired) {
      if ($MODE eq 'sync') { kill ALRM => $$ }
      elsif ($MODE eq 'child') {
        my $parent = $$;
        my $pid = fork;
        if (defined $pid and !$pid) {
          Time::HiRes::sleep(0.05);
          kill ALRM => $parent;
          POSIX::_exit(0);
        }
        push @kids, $pid if $pid;
      }
    }
    return $left;
  };
}

{
  package T::ES::H;
  use base 'DBIO::Test::AsyncHarness';
  sub _tick_loop {
    my ($self) = @_;
    die "the wait did not end: $self->{ticks} turns\n" if ++$self->{ticks} > 50_000_000;
    $self->{on_tick}->() if $self->{on_tick};
    return;
  }
}

sub harness { my (%set) = @_; bless { timeout => 0.3, ticks => 0, %set }, 'T::ES::H' }
sub death_of (&) { my $c = shift; local $@; return eval { $c->(); 1 } ? '(it returned)' : "$@" }
sub reset_mock { local $MODE = 'drop'; Time::HiRes::alarm(0); CORE::alarm(0); $REAL = 1; return }
sub reap { waitpid $_, 0 for splice @kids; return }

# --- the loop spins without a pause; the process lives on ---------------------
for my $mode ('child', 'sync') {
  my $pid = fork;
  die "fork: $!" unless defined $pid;
  if (!$pid) {
    ($MODE, $REAL) = ($mode, 1);
    $SIG{ALRM} = 'DEFAULT';
    my $err = death_of { harness->await(DBIO::Test::Future->new) };
    # Long enough for a signal from a child process to arrive.
    Time::HiRes::sleep(0.3);
    POSIX::_exit($err !~ /^TIMEOUT awaiting Future in T::ES::H/ ? 2
               : $SIG{ALRM} ne 'DEFAULT'                       ? 3
               :                                                 0);
  }
  waitpid $pid, 0;
  is $? & 127, 0, "spinning loop, signal after expiry ($mode): the process is not ended by SIGALRM";
  is $? >> 8, 0, "... await died with TIMEOUT and left \$SIG{ALRM} as it was";
}

# --- the outer alarm survives --------------------------------------------------
for my $mode ('child', 'sync') {
  reset_mock();
  $MODE = $mode;
  my $outer_ran = 0;
  my $marker = sub { $outer_ran++ };
  local $SIG{ALRM} = $marker;
  Time::HiRes::alarm(4);
  my $err = death_of { harness->await(DBIO::Test::Future->new) };
  Time::HiRes::sleep(0.3);
  like $err, qr/^TIMEOUT awaiting Future in T::ES::H/m, "outer alarm, spinning loop ($mode): await dies with TIMEOUT";
  is $outer_ran, 0, "... the handler of the outer alarm has not run";
  is $SIG{ALRM}, $marker, "... \$SIG{ALRM} is the one from before";
  $MODE = 'drop';
  my $rest = Time::HiRes::alarm(0);
  ok $rest > 3 && $rest < 4, "... the outer alarm is still running, due when it was due" or diag "left: $rest";
  reap();
}

# --- a loop that hangs in one call past the grace ------------------------------
{
  reset_mock();
  $MODE = 'drop';
  $REAL = 0;
  my $marker = sub { };
  local $SIG{ALRM} = $marker;
  my $h = harness(timeout => 0.1, on_tick => sub { Time::HiRes::sleep(0.6) });
  my $t0 = Time::HiRes::time();
  my $err = death_of { $h->await(DBIO::Test::Future->new) };
  my $took = Time::HiRes::time() - $t0;
  like $err, qr/^TIMEOUT awaiting Future in T::ES::H/m, 'a loop hanging past the grace, no signal comes: await dies with TIMEOUT';
  is $SIG{ALRM}, $marker, '... \$SIG{ALRM} is the one from before';
  ok $took >= 0.8, '... await waited for the signal that did not come' or diag "took $took";
  ok $took < 1.5, '... and not for long' or diag "took $took";
}

# --- the handler dies in the wait ---------------------------------------------
{
  reset_mock();
  $MODE = 'drop';
  my $marker = sub { };
  local $SIG{ALRM} = $marker;
  my $ticks = 0;
  # The call blocks in select, which returns at the signal. Time::HiRes::sleep
  # of more than a second with a fraction sleeps the fraction after a signal
  # that cut the whole seconds short, and the handler runs only after that.
  my $h = harness(timeout => 0.1, on_tick => sub { select(undef, undef, undef, 10) if ++$ticks == 1 });
  my $t0 = Time::HiRes::time();
  my $err = death_of { $h->await(DBIO::Test::Future->new) };
  my $took = Time::HiRes::time() - $t0;
  like $err, qr/^TIMEOUT awaiting Future in T::ES::H/m, 'a loop blocked in a call: the signal of the timer ends the wait with TIMEOUT';
  ok $took < 1, '... at the time of the alarm, not at the end of the call' or diag "took $took";
  is $SIG{ALRM}, $marker, '... \$SIG{ALRM} is the one from before';
}

# --- an await inside another await, the inner one times out -------------------
#
# The outer await has its timeout running and the file an alarm of its own. The
# inner await times out in a spinning loop; when it is left, the timeout of the
# outer one is back on the clock, and behind it the alarm of the file.
for my $mode ('child', 'sync') {
  my $l = "an await inside another, the inner one times out ($mode)";
  reset_mock();
  my $file_ran = 0;
  local $SIG{ALRM} = sub { $file_ran++ };
  Time::HiRes::alarm(8);
  my $outer = harness(timeout => 3);
  my $inner = harness(timeout => 0.3);
  my $f = DBIO::Test::Future->new;
  my ($inner_death, $left, $want);
  my ($ticks, $entered) = (0, Time::HiRes::time());
  $outer->{on_tick} = sub {
    return unless ++$ticks == 3;
    $MODE = $mode;
    $inner_death = death_of { $inner->await(DBIO::Test::Future->new) };
    Time::HiRes::sleep(0.3);
    $MODE = 'drop';
    # Reading the timer takes it off the line: put it back as it was.
    $left = Time::HiRes::alarm(0);
    $want = 3.25 - (Time::HiRes::time() - $entered);
    Time::HiRes::alarm($left);
    $f->done('outer value');
  };
  my ($value, $outer_death);
  $outer_death = death_of { $value = $outer->await($f) };
  is $value, 'outer value', "$l: the outer await returns its value" or diag $outer_death;
  like $inner_death, qr/^TIMEOUT awaiting Future in T::ES::H/m, "$l: ... the inner one died with TIMEOUT";
  ok $left && abs($left - $want) < 0.1, "$l: the timeout of the outer await is still running, due when it was due"
    or diag "left: " . ($left // 'undef') . ", due in $want";
  is $file_ran, 0, "... the handler of the file's alarm has not run";
  $MODE = 'drop';
  my $rest = Time::HiRes::alarm(0);
  ok $rest > 7 && $rest < 8, "... the alarm of the file is still running, due when it was due" or diag "left: $rest";
  reap();
}

reset_mock();
reap();
done_testing;
