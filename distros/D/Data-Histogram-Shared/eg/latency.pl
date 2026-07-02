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
use Data::Histogram::Shared;

# Latency percentiles with an HdrHistogram. We record a fixed list of response
# times (in microseconds) into a histogram that tracks 1us .. 1s with 3
# significant figures of precision, then report the tail percentiles -- the
# numbers that actually matter for a latency SLO. Memory is a few kilobytes
# regardless of how many samples are recorded.

# Fixed sample set (microseconds): mostly fast, with a long tail.
my @samples = (
    120, 130, 118, 125, 140, 122, 119, 131, 127, 124,
    150, 145, 160, 138, 142, 155, 148, 133, 129, 137,
    200, 210, 250, 180, 220, 190, 205, 215, 195, 230,
    400, 450, 380, 500, 420, 350, 600, 480, 410, 390,
    900, 1200, 1500, 2500, 5000, 800, 1100, 3000, 7500, 12000,
);

# track 1 microsecond .. 1 second, 3 significant figures
my $h = Data::Histogram::Shared->new(undef, 1, 1_000_000, 3);
$h->record_many(\@samples);

printf "recorded %d latency samples (microseconds)\n\n", scalar @samples;

printf "  min   %8d us\n", $h->min;
printf "  mean  %8.1f us\n", $h->mean;
printf "  p50   %8d us\n", $h->value_at_percentile(50);
printf "  p90   %8d us\n", $h->value_at_percentile(90);
printf "  p99   %8d us\n", $h->value_at_percentile(99);
printf "  p99.9 %8d us\n", $h->value_at_percentile(99.9);
printf "  max   %8d us\n", $h->max;

my $st = $h->stats;
printf "\nhistogram: %d counts, %d buckets x %d sub-buckets, %d bytes, %d ops\n",
    @{$st}{qw(counts_len bucket_count sub_bucket_count mmap_size ops)};
printf "precision: %d significant figures (~%.1f%% relative error)\n",
    $st->{sig_figs}, 100 / 10 ** $st->{sig_figs};
