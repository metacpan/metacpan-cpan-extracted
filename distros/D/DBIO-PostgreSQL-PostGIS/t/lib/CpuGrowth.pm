package CpuGrowth;
# Measure how CPU time grows with input size, not how long a run takes on the
# wall clock: a loaded machine slows both runs alike, a quadratic algorithm
# does not hide behind it.
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(cpu_time min_cpu growth_ratio);

sub cpu_time { my ($u, $s) = times; $u + $s }

# Smallest CPU time of $runs runs of $code->($input).
sub min_cpu {
  my ($code, $input, $runs) = @_;
  my $min;
  for (1 .. $runs) {
    my $t0 = cpu_time();
    $code->($input);
    my $t = cpu_time() - $t0;
    $min = $t if !defined $min || $t < $min;
  }
  $min;
}

# growth_ratio(\&build, \&run, $n, $factor, $big_runs) builds the input for $n and for
# $n * $factor BEFORE measuring, then times only $run->($input): the smallest
# of 3 runs for the small input, of $big_runs (default 2) for the big one (it is
# expensive).
# Returns ($ratio, $small_cpu, $big_cpu, $big_result).
#
# Linear growth gives a ratio near $factor (8), quadratic near $factor ** 2
# (64); a limit of 3 * $factor (24) separates them. CPU time ticks at 10 ms,
# so the small run counts as at least 0.05 s, or the division would go by ~0.
sub growth_ratio {
  my ($build, $run, $n, $factor, $big_runs) = @_;
  $big_runs ||= 2;
  my $small_in = $build->($n);
  my $big_in   = $build->($n * $factor);
  my $small = min_cpu($run, $small_in, 3);
  my $result;
  my $big = min_cpu(sub { $result = $run->($_[0]) }, $big_in, $big_runs);
  my $floor = $small < 0.05 ? 0.05 : $small;
  return ($big / $floor, $small, $big, $result);
}

1;
