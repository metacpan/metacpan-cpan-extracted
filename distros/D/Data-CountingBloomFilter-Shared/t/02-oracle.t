use strict;
use warnings;
use Test::More;
use Data::CountingBloomFilter::Shared;

# Deterministic checks. No RNG, no sleep: the only entropy is the fixed XXH3
# hash of fixed input strings, so results are reproducible run to run.

my $CAP = 5000;
my $FP  = 0.01;

# (a) no false negatives: add 5000 distinct items, assert every one is contained.
{
    my $cbf = Data::CountingBloomFilter::Shared->new(undef, $CAP, $FP);
    $cbf->add("in-$_") for 0 .. $CAP - 1;
    my $miss = 0;
    $cbf->contains("in-$_") or $miss++ for 0 .. $CAP - 1;
    is $miss, 0, "no false negatives: all $CAP added items report present";
}

# (b) false-positive rate: query 10000 never-added items, count false positives.
#     Rounding the counter count up to a power of two makes the realised rate <=
#     nominal, so a generous 3x bound is safe and deterministic.
{
    my $cbf = Data::CountingBloomFilter::Shared->new(undef, $CAP, $FP);
    $cbf->add("in-$_") for 0 .. $CAP - 1;
    my $trials = 10_000;
    my $fp = 0;
    for my $i (0 .. $trials - 1) {
        $fp++ if $cbf->contains("out-$i");   # disjoint from the "in-*" keyspace
    }
    my $rate = $fp / $trials;
    diag sprintf("observed false-positive rate: %.4f (%d/%d), target %.4f, k=%d, counters=%d",
                 $rate, $fp, $trials, $FP, $cbf->hashes, $cbf->counters);
    ok $rate <= 3 * $FP,
        sprintf("false-positive rate %.4f <= %.4f (3x target)", $rate, 3 * $FP);
}

# (c) delete oracle: add 5000, remove a disjoint-labelled 2500 that were added,
#     the other 2500 stay present (no false negatives among survivors).
{
    my $cbf = Data::CountingBloomFilter::Shared->new(undef, $CAP, $FP);
    $cbf->add("in-$_") for 0 .. $CAP - 1;
    $cbf->remove("in-$_") for 0 .. ($CAP / 2) - 1;    # remove exactly what we added
    my $miss = 0;
    $cbf->contains("in-$_") or $miss++ for ($CAP / 2) .. $CAP - 1;
    is $miss, 0, "delete: all $CAP/2 non-removed items remain present";
}

# (d) merge: two filters over disjoint 2500-item sets, merged, contain all 5000.
{
    my $half = $CAP / 2;
    my $a = Data::CountingBloomFilter::Shared->new(undef, $CAP, $FP);
    my $b = Data::CountingBloomFilter::Shared->new(undef, $CAP, $FP);
    $a->add("in-$_")              for 0 .. $half - 1;
    $b->add("in-" . ($_ + $half)) for 0 .. $half - 1;
    $a->merge($b);
    my $miss = 0;
    $a->contains("in-$_") or $miss++ for 0 .. $CAP - 1;
    is $miss, 0, "merge of two disjoint $half-item sets contains all $CAP items";
}

# (e) count estimate within 15% of the true 5000 distinct adds.
{
    my $cbf = Data::CountingBloomFilter::Shared->new(undef, $CAP, $FP);
    $cbf->add("in-$_") for 0 .. $CAP - 1;
    my $n = $cbf->count;
    my $err = abs($n - $CAP) / $CAP;
    ok $err < 0.15,
        sprintf("count estimate %d within 15%% of %d (err %.4f)", $n, $CAP, $err);
}

# (f) count_of oracle: with each item added once into a generously-sized filter,
#     count_of never under-counts (always >= 1 for a present item) and is rarely
#     inflated by a colliding fingerprint.
{
    my $N = 2000;
    my $cbf = Data::CountingBloomFilter::Shared->new(undef, 20_000, 0.001);
    $cbf->add("u-$_") for 0 .. $N - 1;
    my ($under, $inflated) = (0, 0);
    for my $i (0 .. $N - 1) {
        my $c = $cbf->count_of("u-$i");
        $under++    if $c < 1;      # would be a false negative -- must never happen
        $inflated++ if $c > 1;      # collision raised the min above the true 1
    }
    is $under, 0, "count_of never under-counts a present item (0 of $N below 1)";
    cmp_ok $inflated, '<', $N / 20, "count_of rarely inflated when well-sized ($inflated/$N)";
}

done_testing;
