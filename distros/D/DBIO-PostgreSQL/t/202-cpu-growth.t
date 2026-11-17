use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use CpuGrowth qw(growth_ratio calibrate);

# Factor 6 (linear near 6, quadratic near 36) with the limit at 3 * factor
# (18). The helper must tell linear from quadratic work, or every test built
# on it proves nothing.
my $factor = 6;
my $limit  = 3 * $factor;
my $build  = sub { $_[0] };    # the input is n itself

# One big run: it is expensive and load only raises its time (and the ratio).
sub probe {
  my ($name, $run, $start, $step, $target, $power) = @_;
  my $n = calibrate($build, $run, $start, $step, $target, $power);
  my ($ratio, $small) = growth_ratio($build, $run, $n, $factor, 1);
  note sprintf '%s: n=%d, small run %.3f s CPU, ratio %.1f', $name, $n, $small, $ratio;
  cmp_ok $small, '>=', 0.05, "$name: small run $small s is above the helper's floor";
  return $ratio;
}

my $lin = probe('linear', sub { my $s = 0; $s += $_ for 1 .. $_[0]; $s }, 1_000_000, 1.25, 0.1, 1);
cmp_ok $lin, '<', $limit, "linear work: ratio $lin is below the limit";

# Quadratic: every number is paired with every later one.
my $quad = probe('quadratic', sub {
  my $n = $_[0]; my $c = 0;
  for my $i (1 .. $n) { for my $j ($i + 1 .. $n) { $c++ } }
  $c;
}, 1_000, 1.05, 0.1, 2);
cmp_ok $quad, '>', $limit, "quadratic work: ratio $quad is above the limit";

done_testing;
