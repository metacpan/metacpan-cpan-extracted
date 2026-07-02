use strict;
use warnings;
use Test::More;
use Data::BloomFilter::Shared;

# Deterministic checks. No RNG, no sleep: the only entropy is the fixed XXH3
# hash of fixed input strings, so results are reproducible run to run.

my $CAP = 5000;
my $FP  = 0.01;

# (a) no false negatives: add 5000 distinct items, assert every one is contained.
{
    my $bf = Data::BloomFilter::Shared->new(undef, $CAP, $FP);
    $bf->add("in-$_") for 0 .. $CAP - 1;
    my $miss = 0;
    $bf->contains("in-$_") or $miss++ for 0 .. $CAP - 1;
    is $miss, 0, "no false negatives: all $CAP added items report present";
}

# (b) false-positive rate: query 10000 never-added items, count false positives.
#     Rounding the bit count up to a power of two makes the realised rate <=
#     nominal, so a generous 3x bound is safe and deterministic.
{
    my $bf = Data::BloomFilter::Shared->new(undef, $CAP, $FP);
    $bf->add("in-$_") for 0 .. $CAP - 1;
    my $trials = 10_000;
    my $fp = 0;
    for my $i (0 .. $trials - 1) {
        $fp++ if $bf->contains("out-$i");   # disjoint from the "in-*" keyspace
    }
    my $rate = $fp / $trials;
    diag sprintf("observed false-positive rate: %.4f (%d/%d), target %.4f, k=%d, bits=%d",
                 $rate, $fp, $trials, $FP, $bf->hashes, $bf->bits);
    ok $rate <= 3 * $FP,
        sprintf("false-positive rate %.4f <= %.4f (3x target)", $rate, 3 * $FP);
}

# (c) merge: two filters over disjoint 2500-item sets, merged, contain all 5000
#     with no extra false negatives.
{
    my $half = $CAP / 2;
    my $a = Data::BloomFilter::Shared->new(undef, $CAP, $FP);
    my $b = Data::BloomFilter::Shared->new(undef, $CAP, $FP);
    $a->add("in-$_")        for 0 .. $half - 1;
    $b->add("in-" . ($_ + $half)) for 0 .. $half - 1;
    $a->merge($b);
    my $miss = 0;
    $a->contains("in-$_") or $miss++ for 0 .. $CAP - 1;
    is $miss, 0, "merge of two disjoint $half-item sets contains all $CAP items";
}

# (d) count estimate within 15% of the true 5000 distinct adds.
{
    my $bf = Data::BloomFilter::Shared->new(undef, $CAP, $FP);
    $bf->add("in-$_") for 0 .. $CAP - 1;
    my $n = $bf->count;
    my $err = abs($n - $CAP) / $CAP;
    ok $err < 0.15,
        sprintf("count estimate %d within 15%% of %d (err %.4f)", $n, $CAP, $err);
}

done_testing;
