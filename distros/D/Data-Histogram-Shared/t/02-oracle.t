use strict;
use warnings;
use Test::More;
use Data::Histogram::Shared;

# Deterministic checks. No RNG, no sleep: a uniform multiset 1..100000 recorded
# into a (1, 1_000_000, 3) histogram has a known true distribution, so the
# percentile / min / max / mean answers are reproducible run to run and can be
# checked against closed-form expectations within the 3-significant-figure
# (0.1%) precision contract.

my $LOW  = 1;
my $HIGH = 1_000_000;
my $SIG  = 3;
my $N    = 100_000;

my $h = Data::Histogram::Shared->new(undef, $LOW, $HIGH, $SIG);
$h->record($_) for 1 .. $N;

# (a) percentile accuracy: the true p-th percentile of the uniform set 1..N is
#     ~ p/100 * N = p*1000. HdrHistogram returns the highest-equivalent value of
#     the bucket, so allow the 0.1% relative tolerance plus a small slack.
{
    for my $p (10, 25, 50, 75, 90, 99) {
        my $got  = $h->value_at_percentile($p);
        my $true = $p * 1000;                 # p-th percentile of 1..100000
        my $tol  = $true * 0.001 + 2;         # ~0.1% (3 sig figs) + slack
        ok abs($got - $true) <= $tol,
            sprintf("p%d: got %d, true ~%d, |err| %d <= tol %.1f", $p, $got, $true, abs($got - $true), $tol)
            or diag sprintf("p%d off by %d (%.4f%%)", $p, abs($got - $true), abs($got - $true) / $true * 100);
    }
}

# (b) min == 1, max == 100000, count == 100000.
{
    is $h->total_count, $N, "count == $N";
    is $h->min, 1, 'min == 1 (exact)';
    is $h->max, $N, "max == $N (exact)";
}

# (c) equivalence round-trip: a recorded value lands in a bucket whose
#     [lowest_equiv, highest_equiv] range contains it, so count_at_value sees it.
{
    my $bad = 0;
    for my $v (1, 2, 3, 7, 99, 100, 101, 1000, 12345, 54321, 99999, 100000) {
        # count_at_value buckets values equivalent to $v together; each distinct
        # value 1..N was recorded exactly once, but several may share a bucket at
        # large magnitudes, so the bucket count is >= 1 and the value is tracked.
        $bad++ unless $h->count_at_value($v) >= 1;
    }
    is $bad, 0, 'equivalence round-trip: every sampled recorded value is found in its bucket';

    # A fresh single-value histogram: highest_equivalent(v) >= v >= recorded, and
    # the bucket count is exactly 1.
    my $bad2 = 0;
    for my $v (1, 100, 999, 5000, 50000, 999999) {
        my $g = Data::Histogram::Shared->new(undef, $LOW, $HIGH, $SIG);
        $g->record($v);
        my $hi = $g->value_at_percentile(100);   # highest-equivalent of v's bucket
        $bad2++ unless $hi >= $v && abs($hi - $v) / $v <= 0.001 && $g->count_at_value($v) == 1;
    }
    is $bad2, 0, 'single-value equivalence: highest_equiv >= v within 0.1%, count 1';
}

# (d) merge: two histograms over disjoint halves, merged percentiles match a
#     single histogram with all 100000 values.
{
    my $a   = Data::Histogram::Shared->new(undef, $LOW, $HIGH, $SIG);
    my $b   = Data::Histogram::Shared->new(undef, $LOW, $HIGH, $SIG);
    my $all = Data::Histogram::Shared->new(undef, $LOW, $HIGH, $SIG);
    for my $i (1 .. 50_000)        { $a->record($i);  $all->record($i) }
    for my $i (50_001 .. 100_000)  { $b->record($i);  $all->record($i) }
    $a->merge($b);

    is $a->total_count, $all->total_count, 'merge: total_count matches the single histogram';
    is $a->min, $all->min, 'merge: min matches';
    is $a->max, $all->max, 'merge: max matches';
    my $bad = 0;
    for my $p (10, 25, 50, 75, 90, 99, 100) {
        $bad++ unless $a->value_at_percentile($p) == $all->value_at_percentile($p);
    }
    is $bad, 0, 'merge: every percentile equals the single-histogram percentile';
}

# (e) mean ~ 50000 (true mean of 1..100000 is 50000.5) within 0.1%.
{
    my $mean = $h->mean;
    my $true = ($N + 1) / 2;   # 50000.5
    ok abs($mean - $true) / $true <= 0.001,
        sprintf("mean %.2f ~ %.1f within 0.1%% (err %.4f%%)", $mean, $true, abs($mean - $true) / $true * 100);
}

done_testing;
