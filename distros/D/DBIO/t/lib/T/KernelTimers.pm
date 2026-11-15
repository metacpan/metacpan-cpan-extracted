package T::KernelTimers;
use strict;
use warnings;
use Test::More ();
use Time::HiRes ();

# How much slower than Time::HiRes::time() the kernel timers of this host run
# (the sleep and the alarm), measured, and a layer over Time::HiRes::sleep and
# Time::HiRes::alarm that makes a timer keep the clock again: with the layer
# in, sleep(x) and alarm(x) take x seconds of the clock. A test file measures
# in a BEGIN block, before it loads what it tests and before it sets mocks of
# its own:
#
#   use lib 't/lib';
#   use T::KernelTimers;
#
# On a host where timers and clock agree the layer is not installed and
# nothing changes. A host further off than $LIMIT is beyond what the files
# using this carry: their ticks (0.002s) divided by the factor get down to the
# resolution of the kernel timer itself, which a wait cannot be counted in. They skip.

our $K     = 1;
our $LIMIT = 4;

sub factor { $K }

# What counts as slower: the least ratio of several samples (load makes a
# ratio larger, never smaller), and under NOISE no slower at all.
my $NOISE   = 1.25;
my $SAMPLES = 3;

sub _measure {
  my $least;
  for (1 .. $SAMPLES) {
    my $fired = 0;
    local $SIG{ALRM} = sub { $fired = 1 };
    my $t = Time::HiRes::time();
    Time::HiRes::alarm(0.2);
    Time::HiRes::sleep(0.01) until $fired;
    my $by_alarm = (Time::HiRes::time() - $t) / 0.2;

    $t = Time::HiRes::time();
    Time::HiRes::sleep(0.05);
    my $by_sleep = (Time::HiRes::time() - $t) / 0.05;

    for my $ratio ($by_alarm, $by_sleep) {
      $least = $ratio if !defined $least or $ratio < $least;
    }
  }
  return $least < $NOISE ? 1 : $least;
}

sub import {
  $K = _measure();
  Test::More::note(sprintf 'kernel timers run %.2f times slower than the clock', $K)
    if $K > 1;
  Test::More::plan(skip_all => sprintf
    'Kernel timers run %.1f times slower than the clock: beyond the %d times these waits carry',
    $K, $LIMIT) if $K > $LIMIT;
  return unless $K > 1;

  my %real = (sleep => \&Time::HiRes::sleep, alarm => \&Time::HiRes::alarm);
  my $k = $K;
  no warnings 'redefine';
  *Time::HiRes::sleep = sub (;@) { $real{sleep}->($_[0] / $k) };
  *Time::HiRes::alarm = sub ($;$) {
    my ($secs, $interval) = @_;
    my $rest = $real{alarm}->($secs / $k, defined $interval ? $interval / $k : ());
    return $rest * $k;
  };
  return;
}

1;
