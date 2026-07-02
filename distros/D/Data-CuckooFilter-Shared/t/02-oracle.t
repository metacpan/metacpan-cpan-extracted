use strict;
use warnings;
use Test::More;
use Data::CuckooFilter::Shared;

# Deterministic checks. No RNG, no sleep beyond the filter's internal xorshift:
# the only entropy is the fixed XXH3 hash of fixed input strings, so results are
# reproducible run to run.

my $CAP = 5000;

# (a) no false negatives: add 5000 distinct items, every one contains()==1,
#     count == 5000.
{
    my $cf = Data::CuckooFilter::Shared->new(undef, $CAP);
    my $store_miss = 0;
    for my $i (0 .. $CAP - 1) { $cf->add("in-$i") or $store_miss++ }
    is $store_miss, 0, "all $CAP adds were stored (not full)";
    my $miss = 0;
    $cf->contains("in-$_") or $miss++ for 0 .. $CAP - 1;
    is $miss, 0, "no false negatives: all $CAP added items report present";
    is $cf->count, $CAP, "count == $CAP after $CAP distinct adds";
}

# (b) false-positive rate: query 10000 never-added items, count false positives.
#     Actual rate ~ 2*4/65536 ~= 0.00012; assert a generous <= 0.01 bound.
{
    my $cf = Data::CuckooFilter::Shared->new(undef, $CAP);
    $cf->add("in-$_") for 0 .. $CAP - 1;
    my $trials = 10_000;
    my $fp = 0;
    for my $i (0 .. $trials - 1) {
        $fp++ if $cf->contains("out-$i");   # disjoint from the "in-*" keyspace
    }
    my $rate = $fp / $trials;
    diag sprintf("observed false-positive rate: %.5f (%d/%d), bound 0.01000, buckets=%d, slots=%d",
                 $rate, $fp, $trials, $cf->buckets, $cf->slots);
    ok $rate <= 0.01,
        sprintf("false-positive rate %.5f <= 0.01000 (generous bound)", $rate);
}

# (c) delete churn: add 5000, remove the 2500 even-indexed; the odd-indexed
#     2500 must all still be contained (no false negatives), count == 2500, and
#     the removed even ones are mostly absent (allow a small fingerprint-
#     collision slack: >= 2490 of 2500 absent).
{
    my $cf = Data::CuckooFilter::Shared->new(undef, $CAP);
    $cf->add("in-$_") for 0 .. $CAP - 1;
    $cf->remove("in-$_") for grep { $_ % 2 == 0 } 0 .. $CAP - 1;   # remove even indices

    my $odd_miss = 0;
    for my $i (grep { $_ % 2 == 1 } 0 .. $CAP - 1) {
        $cf->contains("in-$i") or $odd_miss++;
    }
    is $odd_miss, 0, 'delete churn: all 2500 odd-indexed items still contained (no false negatives)';
    is $cf->count, 2500, 'delete churn: count == 2500 after removing 2500 of 5000';

    my $absent = 0;
    for my $i (grep { $_ % 2 == 0 } 0 .. $CAP - 1) {
        $absent++ unless $cf->contains("in-$i");
    }
    cmp_ok $absent, '>=', 2490,
        sprintf('delete churn: removed even-indexed items mostly absent (%d/2500 absent, slack for fp collisions)', $absent);
}

# (d) fill-to-capacity: a small filter (capacity 1000); add distinct items until
#     add() returns 0 or well past capacity; assert it accepted at least
#     0.90*capacity before returning 0, and that EVERY item add() returned 1 for
#     is still contained (atomic-insert / no-false-negative guarantee even at the
#     full boundary -- exercises the rollback path).
{
    my $small = 1000;
    my $cf = Data::CuckooFilter::Shared->new(undef, $small);
    my @stored;                 # items add() accepted
    my $limit = $small * 4;     # add well past capacity if it never fills
    my $accepted = 0;
    my $hit_full = 0;
    for my $i (0 .. $limit - 1) {
        if ($cf->add("fill-$i")) {
            push @stored, "fill-$i";
            $accepted++;
        } else {
            $hit_full = 1;
            last;
        }
    }
    diag sprintf("fill-to-capacity: accepted %d items (capacity %d, %.1f%%), hit_full=%d, slots=%d",
                 $accepted, $small, 100 * $accepted / $small, $hit_full, $cf->slots);
    cmp_ok $accepted, '>=', 0.90 * $small,
        sprintf('accepted at least 90%% of capacity before full (%d >= %d)', $accepted, int(0.90 * $small));

    # count must equal the number of accepted (stored) fingerprints exactly
    is $cf->count, $accepted, 'count equals the number of accepted inserts';

    # EVERY accepted item must still be present: a failed (full) add rolled back
    # cleanly and never displaced a stored fingerprint.
    my $miss = 0;
    for my $it (@stored) { $cf->contains($it) or $miss++ }
    is $miss, 0,
        'no false negatives at the full boundary: every accepted item is still contained (rollback verified)';
}

done_testing;
