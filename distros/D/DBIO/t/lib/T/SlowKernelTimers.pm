package T::SlowKernelTimers;
use strict;
use warnings;
use Time::HiRes ();

# Proof helper, loaded from the environment only, never by a test file:
#
#   PERL5OPT="-Mlib=t/lib -MT::SlowKernelTimers" SLOW_KERNEL_TIMERS=2 prove -l t/test/54_...t
#
# It simulates a host whose kernel timers (sleep, alarm) run SLOW_KERNEL_TIMERS
# times slower than Time::HiRes::time(): every sleep and every alarm takes that
# many times as long on the clock as it was asked for. The clock is unchanged.

our $F;

BEGIN {
  $F = $ENV{SLOW_KERNEL_TIMERS} || 1;

  my %real = map { $_ => \&{"Time::HiRes::$_"} } qw(sleep usleep nanosleep alarm ualarm);
  my $core_alarm = sub { CORE::alarm($_[0]) };
  my $core_sleep = sub { CORE::sleep($_[0]) };

  no strict 'refs';
  no warnings 'redefine';

  *Time::HiRes::sleep     = sub (;@) { $real{sleep}->($_[0] * $F) };
  *Time::HiRes::usleep    = sub ($) { $real{usleep}->($_[0] * $F) };
  *Time::HiRes::nanosleep = sub ($) { $real{nanosleep}->($_[0] * $F) };

  # A timer set for x runs for x * F; what it reports as left is the rest as
  # the caller counts it.
  *Time::HiRes::alarm = sub ($;$) {
    my ($secs, $interval) = @_;
    my $rest = $real{alarm}->($secs * $F, defined $interval ? $interval * $F : ());
    return $rest / $F;
  };
  *Time::HiRes::ualarm = sub ($;$) {
    my ($usecs, $interval) = @_;
    my $rest = $real{ualarm}->($usecs * $F, defined $interval ? $interval * $F : ());
    return $rest / $F;
  };

  *CORE::GLOBAL::alarm = sub (;$) {
    my $secs = @_ ? $_[0] : $_;
    my $rest = $core_alarm->($secs * $F);
    return int($rest / $F + 0.999999);
  };
  *CORE::GLOBAL::sleep = sub (;$) {
    return $core_sleep->() unless @_;
    my $start = Time::HiRes::time();
    $core_sleep->($_[0] * $F);
    return int((Time::HiRes::time() - $start) / $F + 0.5);
  };
}

1;
