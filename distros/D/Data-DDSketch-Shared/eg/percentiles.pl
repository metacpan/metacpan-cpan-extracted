#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
# Prefer a freshly built blib/ (picks up both lib and the compiled .so),
# fall back to lib/ or the installed module.
BEGIN {
    my $blib = "$FindBin::Bin/../blib";
    if (-d "$blib/arch") { require blib; blib->import($blib) }
    else { unshift @INC, "$FindBin::Bin/../lib" }
}
use Data::DDSketch::Shared;

# Summarise a long-tailed latency distribution with relative-error quantiles.
# A DDSketch keeps the p50/p90/p99/p99.9 accurate to a fixed relative error in a
# few kilobytes, no matter how many samples arrive -- exactly what a fixed-bucket
# histogram struggles with when latencies span microseconds to seconds.

my $alpha = 0.01;                          # 1% relative accuracy
my $dd = Data::DDSketch::Shared->new(undef, $alpha);

# deterministic pseudo-random latencies (ms): mostly fast, with a heavy tail
my $seed = 424242;
sub rnd { $seed = ($seed * 1103515245 + 12345) & 0x7fffffff; $seed / 0x7fffffff }

for (1 .. 1_000_000) {
    my $u = rnd();
    # exponential-ish body + occasional slow outliers
    my $ms = -20 * log(1 - $u);
    $ms += 500 + 1500 * rnd() if rnd() < 0.005;    # 0.5% slow requests
    $dd->add($ms);
}

printf "fed %d latency samples, alpha=%.0f%%\n\n", $dd->count, $alpha * 100;
printf "count    %d\n",     $dd->count;
printf "min      %.3f ms\n", $dd->min;
printf "mean     %.3f ms\n", $dd->mean;
printf "max      %.3f ms\n", $dd->max;
print  "\n";
for my $q (0.5, 0.9, 0.95, 0.99, 0.999) {
    printf "p%-5s   %.3f ms\n", $q * 100, $dd->quantile($q);
}
