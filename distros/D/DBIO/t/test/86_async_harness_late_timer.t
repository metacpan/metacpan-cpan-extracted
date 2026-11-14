use strict;
use warnings;
use Test::More;
use DBIO::Test::Slow;
use Time::HiRes ();
use POSIX ();

# An alarm of the file that is due before await's timeout has to fire, at its
# time, under its own handler -- also where a timer is not delivered the
# instant it is due. On FreeBSD, NetBSD and macOS the signal follows the expiry
# by a tick of the kernel clock, and in that gap the timer is reported as 0
# left: await has to wait the delay out and not take that for "fired", or its
# alarm(0) cancels the signal and nothing ever ends the wait. On Cygwin a timer
# that has fired reports a NEGATIVE time left, which must not be taken for a
# running one (it would re-arm it and fire the handler twice).
#
# The signal may be a lot later than a tick: await does not guess how long, it
# waits until the handler has run. So the same holds when the signal comes
# 0.5s or 1.5s after the expiry -- for a handler that returns (the wait goes on
# to its own timeout, the handler having run once), for one that dies (the
# death arrives) and for DEFAULT (the process ends by SIGALRM; seen in a child).
#
# Simulated here on any host by a Time::HiRes::alarm that delivers LATE and
# answers as those systems do.

BEGIN {
  plan skip_all => 'Time::HiRes::alarm is not implemented on this platform'
    unless eval { Time::HiRes::alarm(0); 1 };
}

our $LATE = 0.03;
my $NEGATIVE_WHEN_FIRED = 0;
my $expiry;

BEGIN {
  my $real = \&Time::HiRes::alarm;
  no warnings 'redefine';
  *Time::HiRes::alarm = sub ($;$) {
    my ($secs) = @_;
    my $now  = Time::HiRes::time();
    my $left = defined $expiry ? $expiry - $now : 0;
    $left = 0 if $left < 0 and !$NEGATIVE_WHEN_FIRED;
    $real->(0);
    if ($secs > 0) { $expiry = $now + $secs; $real->($secs + $LATE) }
    else           { $expiry = undef }
    return $left;
  };
}

use DBIO::Test::Future ();
use DBIO::Test::AsyncHarness;

{
  package T::LT::H;
  use base 'DBIO::Test::AsyncHarness';
  sub _tick_loop {
    my ($self) = @_;
    die "the wait did not end: $self->{ticks} turns\n" if ++$self->{ticks} > 400;
    Time::HiRes::sleep(0.01);
    return;
  }
}

sub harness { my (%set) = @_; bless { ticks => 0, %set }, 'T::LT::H' }
sub death_of (&) { my $c = shift; local $@; return eval { $c->(); 1 } ? '(it returned)' : "$@" }

{
  local $SIG{ALRM} = sub { die "the file's own alarm\n" };
  Time::HiRes::alarm(0.3);
  my $h = harness(timeout => 5);
  like death_of { $h->await(DBIO::Test::Future->new) }, qr/^the file's own alarm$/m,
    'an alarm delivered late, due before the timeout: it still ends the wait';
  Time::HiRes::alarm(0);
}

{
  $NEGATIVE_WHEN_FIRED = 1;
  my $ran = 0;
  local $SIG{ALRM} = sub { $ran++ };
  Time::HiRes::alarm(0.2);
  my $h = harness(timeout => 0.6);
  like death_of { $h->await(DBIO::Test::Future->new) }, qr/TIMEOUT awaiting Future in T::LT::H/,
    'a handler that returns, the timer answering negative once fired: the wait ends on the timeout';
  is $ran, 1, '... and the alarm fired once';
  Time::HiRes::alarm(0);
}

for my $late (0.5, 1.5) {
  local $LATE = $late;
  $NEGATIVE_WHEN_FIRED = 0;

  {
    my $ran = 0;
    local $SIG{ALRM} = sub { $ran++ };
    Time::HiRes::alarm(0.2);
    my $h = harness(timeout => 0.2 + $late + 0.8);
    like death_of { $h->await(DBIO::Test::Future->new) }, qr/TIMEOUT awaiting Future in T::LT::H/,
      "signal ${late}s late, handler returns: the wait ends on its own timeout";
    is $ran, 1, '... the handler ran exactly once';
    Time::HiRes::alarm(0);
  }

  {
    local $SIG{ALRM} = sub { die "the file's own alarm\n" };
    Time::HiRes::alarm(0.2);
    my $h = harness(timeout => 0.2 + $late + 0.8);
    like death_of { $h->await(DBIO::Test::Future->new) }, qr/^the file's own alarm$/m,
      "signal ${late}s late, handler dies: the death arrives";
    Time::HiRes::alarm(0);
  }

  {
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (!$pid) {
      $SIG{ALRM} = 'DEFAULT';
      Time::HiRes::alarm(0.2);
      eval { harness(timeout => 0.2 + $late + 0.8)->await(DBIO::Test::Future->new) };
      POSIX::_exit(3);
    }
    waitpid $pid, 0;
    is $? & 127, POSIX::SIGALRM(), "signal ${late}s late, DEFAULT: the process ends by SIGALRM";
  }
}

done_testing;
