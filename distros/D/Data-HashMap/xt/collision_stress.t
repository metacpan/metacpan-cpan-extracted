use strict;
use warnings;
use Test::More;

use Data::HashMap::II;

# Force heavy collisions by crafting keys that all hash into the same bucket.
# For II the bucket is `hash64(key) & (capacity - 1)`. We can't predict hash64
# exactly, but we CAN insert N keys and ensure N > capacity/4, forcing many
# collisions in practice and exercising the long-probe / tombstone-jump path.

{
    my $m = Data::HashMap::II->new();
    my $N = 10_000;
    $m->reserve($N);

    # Insert, delete half, re-insert new — stresses tombstone probing
    $m->put($_, $_ * 7) for 1 .. $N;
    is $m->size, $N, "inserted $N keys";

    $m->remove($_) for grep { $_ % 2 == 0 } 1 .. $N;
    is $m->size, $N / 2, "removed half, $N/2 remain";

    # Re-insert disjoint keys into the tombstoned slots
    $m->put($_, -$_) for ($N + 1) .. ($N + $N / 2);
    is $m->size, $N, "re-inserted, size back to $N";

    # Verify every odd original key + every new key is retrievable
    my $hits = 0;
    for my $k ((grep { $_ % 2 == 1 } 1..$N), ($N+1) .. ($N + $N/2)) {
        $hits++ if defined $m->get($k);
    }
    is $hits, $N, 'all live keys retrievable after collision stress';
}

# Tombstone-path stress: insert, delete in reverse order — probes must
# correctly jump tombstones to find originals.

{
    my $m = Data::HashMap::II->new();
    $m->put($_, $_) for 1 .. 1000;
    # Delete keys in the REVERSE probe order by spacing
    $m->remove($_) for map { $_ * 7 + 1 } 0 .. 142;
    # Originals that weren't deleted must still be findable
    my $found = 0;
    for my $k (1..1000) {
        next if $k == (int(($k - 1) / 7) * 7 + 1);
        $found++ if defined $m->get($k);
    }
    cmp_ok $found, '>', 800, 'undeleted keys findable after reverse-probe removal';
}

# Resize during heavy tombstone load
{
    my $m = Data::HashMap::II->new();
    # Alternate insert / remove / insert to grow tombstones toward compact threshold
    for (1..2000) {
        $m->put($_, $_);
        $m->remove($_ - 100) if $_ > 100;
    }
    cmp_ok $m->size, '>', 0, 'map non-empty after insert/remove churn';
    # Force a compact
    $m->put(9_999_999, 1);
    is $m->get(9_999_999), 1, 'post-churn insert still retrievable';
}

done_testing;
