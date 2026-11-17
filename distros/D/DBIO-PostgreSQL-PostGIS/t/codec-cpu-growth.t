use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use CpuGrowth qw(growth_ratio min_cpu);

# Factor 6 (linear near 6, quadratic near 36) with the limit at 3 * factor
# (18), as in the codec tests built on the helper. The helper must tell linear
# from quadratic work, or those tests prove nothing.
my $factor = 6;
my $limit  = 3 * $factor;
my $build  = sub { $_[0] };    # the input is n itself

# Raise n until the small run (smallest of 3, as growth_ratio measures it)
# needs $target s of CPU time: at least twice the helper's 0.05 s floor even in
# the worst run, so the ratio is real growth on a CPU of any speed. Coarse
# stage: x1.5 steps, one run each, up to 0.05 s. Then n jumps to 5% below the
# target, extrapolated for work growing as n ** $power. Fine stage: $step up to
# $target.
sub calibrate {
  my ($run, $n, $step, $target, $power) = @_;
  my $cpu;
  $n = int($n * 1.5) + 1 until ($cpu = min_cpu($run, $n, 1)) >= 0.05;
  $n = int($n * 0.95 * ($target / $cpu) ** (1 / $power)) + 1;
  $n = int($n * $step) + 1 until min_cpu($run, $n, 3) >= $target;
  $n;
}

# One big run: it is expensive and load only raises its time (and the ratio).
sub probe {
  my ($name, $run, $start, $step, $target, $power) = @_;
  my $n = calibrate($run, $start, $step, $target, $power);
  my ($ratio, $small) = growth_ratio($build, $run, $n, $factor, 1);
  note sprintf '%s: n=%d, small run %.3f s CPU, ratio %.1f', $name, $n, $small, $ratio;
  cmp_ok $small, '>=', 0.05, "$name: small run $small s is above the helper's floor";
  return $ratio;
}

my $lin = probe('linear', sub { my $s = 0; $s += $_ for 1 .. $_[0]; $s }, 1_000_000, 1.25, 0.2, 1);
cmp_ok $lin, '<', $limit, "linear work: ratio $lin is below the limit";

# Quadratic: every number is paired with every later one.
my $quad = probe('quadratic', sub {
  my $n = $_[0]; my $c = 0;
  for my $i (1 .. $n) { for my $j ($i + 1 .. $n) { $c++ } }
  $c;
}, 1_000, 1.05, 0.12, 2);
cmp_ok $quad, '>', $limit, "quadratic work: ratio $quad is above the limit";

done_testing;
