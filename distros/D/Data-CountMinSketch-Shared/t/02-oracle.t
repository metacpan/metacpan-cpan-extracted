use strict;
use warnings;
use Test::More;
use Data::CountMinSketch::Shared;

# Deterministic checks. No RNG, no sleep: the only entropy is the fixed XXH3
# hash of fixed input strings, so results are reproducible run to run.

my $EPS = 0.001;
my $DELTA = 0.001;
my $N = 2000;

# Build a multiset of $N distinct keys "k$i" each added $i times.
#   total = sum(1..N) = N*(N+1)/2  (~2e6 for N=2000)
my $cms = Data::CountMinSketch::Shared->new(undef, $EPS, $DELTA);
for my $i (1 .. $N) {
    $cms->add("k$i", $i);
}
my $total = $N * ($N + 1) / 2;

# (a) never underestimates: estimate("k$i") >= i for ALL i (hard CMS guarantee).
{
    my $under = 0;
    my $worst_key = '';
    for my $i (1 .. $N) {
        my $e = $cms->estimate("k$i");
        if ($e < $i) { $under++; $worst_key = "k$i ($e < $i)" unless $worst_key; }
    }
    is $under, 0, "never underestimates: estimate(k\$i) >= i for all $N keys"
        or diag "first underestimate: $worst_key";
}

# (b) error bound: overestimate (estimate - i) <= epsilon*total for at least
#     (1 - 2*delta) of the keys; and MAX overestimate <= epsilon*total*5.
{
    is $cms->total, $total, "total equals the sum of all increments ($total)";
    my $bound = $EPS * $total;
    my $within = 0;
    my $max_over = 0;
    for my $i (1 .. $N) {
        my $e = $cms->estimate("k$i");
        my $over = $e - $i;          # >= 0 by (a)
        $max_over = $over if $over > $max_over;
        $within++ if $over <= $bound;
    }
    my $frac = $within / $N;
    diag sprintf("error bound: epsilon*total = %.1f; within-bound fraction %.4f (%d/%d); max overestimate %d; w=%d d=%d",
                 $bound, $frac, $within, $N, $max_over, $cms->width, $cms->depth);
    ok $frac >= (1 - 2 * $DELTA),
        sprintf("at least %.4f of keys within epsilon*total (got %.4f)", 1 - 2 * $DELTA, $frac);
    ok $max_over <= $bound * 5,
        sprintf("max overestimate %d <= 5*epsilon*total (%.1f)", $max_over, $bound * 5);
}

# (c) Merge equals a combined stream, including when collisions change which
#     row gives the minimum in each input.
{
    my $a = Data::CountMinSketch::Shared->new(undef, 0.1, $DELTA);
    my $b = Data::CountMinSketch::Shared->new(undef, 0.1, $DELTA);
    my $combined = Data::CountMinSketch::Shared->new(undef, 0.1, $DELTA);
    my $M = 200;
    for my $i (1 .. $M) {
        $a->add("a$i", $i);
        $b->add("b$i", $i * 2);
        $combined->add("a$i", $i);
        $combined->add("b$i", $i * 2);
    }
    my @keys = map { ("a$_", "b$_", "absent$_") } 1 .. $M;
    my %sums = map { ($_ => $a->estimate($_) + $b->estimate($_)) } @keys;

    my $ta = $a->total;
    my $tb = $b->total;

    $a->merge($b);

    my ($bad, $below, $above) = (0, 0, 0);
    for my $key (@keys) {
        my $estimate = $a->estimate($key);
        $bad++ if $estimate != $combined->estimate($key);
        $below++ if $estimate < $sums{$key};
        $above++ if $estimate > $sums{$key};
    }
    is $bad, 0, 'merge estimates match counting both streams into one sketch';
    is $below, 0, 'merged minimum is at least the sum of the separate minima';
    cmp_ok $above, '>', 0, 'collisions can make merged estimates exceed that sum';
    is $a->total, $ta + $tb, 'merge: total == sum of both input totals';
}

# (d) total: equals the sum of all increments (already checked in (b), restate
#     explicitly here for a fresh sketch).
{
    my $h = Data::CountMinSketch::Shared->new(undef, $EPS, $DELTA);
    my $sum = 0;
    for my $i (1 .. 1000) {
        my $c = ($i % 7) + 1;
        $h->add("t$i", $c);
        $sum += $c;
    }
    is $h->total, $sum, "total equals the sum of all increments ($sum)";
}

done_testing;
