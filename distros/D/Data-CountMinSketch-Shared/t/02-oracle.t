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

# (c) merge: two sketches over disjoint key sets, merged estimate == sum of the
#     two estimates for every key (cellwise-add soundness).
{
    my $a = Data::CountMinSketch::Shared->new(undef, $EPS, $DELTA);
    my $b = Data::CountMinSketch::Shared->new(undef, $EPS, $DELTA);
    # a gets keys "a$i" added $i times; b gets keys "b$i" added (i*2) times
    my $M = 500;
    for my $i (1 .. $M) {
        $a->add("a$i", $i);
        $b->add("b$i", $i * 2);
    }
    # snapshot the pre-merge estimates for every key in both sets
    my %ea = map { ("a$_" => $a->estimate("a$_")) } 1 .. $M;
    my %eb_a = map { ("b$_" => $a->estimate("b$_")) } 1 .. $M;   # a's view of b's keys (collisions)
    my %ea_b = map { ("a$_" => $b->estimate("a$_")) } 1 .. $M;   # b's view of a's keys (collisions)
    my %eb = map { ("b$_" => $b->estimate("b$_")) } 1 .. $M;

    my $ta = $a->total;
    my $tb = $b->total;

    $a->merge($b);

    my $bad = 0;
    for my $i (1 .. $M) {
        my $ka = "a$i"; my $kb = "b$i";
        $bad++ unless $a->estimate($ka) == $ea{$ka} + $ea_b{$ka};
        $bad++ unless $a->estimate($kb) == $eb_a{$kb} + $eb{$kb};
    }
    is $bad, 0, "merge: estimate(k) == sum of the two pre-merge estimates for every key";
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
