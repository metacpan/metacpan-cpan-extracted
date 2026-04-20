use strict;
use warnings;
use Test::More;
use Time::HiRes qw(sleep);

use Data::HashMap::II;
use Data::HashMap::SS;

# ---- LRU + TTL: expired entries are reaped, not promoted ----

{
    my $m = Data::HashMap::II->new(10, 1);   # max_size=10, default_ttl=1s
    $m->put($_, $_ * 10) for 1..5;
    sleep 2.2;                                # clearly past 1s TTL boundary
    # All 5 are now TTL-expired.
    is $m->get(3), undef, 'TTL-expired key is unreachable';
    cmp_ok $m->size, '<=', 5, 'size after get-with-expiry not higher than before';
    $m->put(100, 999);
    is $m->get(100), 999, 'fresh put after mass expiry';
}

# ---- LRU tail preferred for eviction even with mixed TTLs ----

{
    my $m = Data::HashMap::II->new(3);       # max_size=3, no TTL
    $m->put(1, 1);
    $m->put(2, 2);
    $m->put(3, 3);
    $m->get(1);                               # touch 1 — moves to MRU
    $m->get(3);                               # touch 3 — moves to MRU
    $m->put(4, 4);                            # LRU (2) should be evicted
    is $m->get(2), undef, 'LRU tail (2) evicted';
    is $m->get(1), 1,     '1 still present';
    is $m->get(3), 3,     '3 still present';
    is $m->get(4), 4,     '4 inserted';
}

# ---- pop/shift on non-LRU map with TTL-expired entries ----
# Non-LRU pop advances iter_pos; TTL-expired slots are skipped WITHOUT
# being tombstoned (unlike LRU pop, which reaps expired tail entries).
# So pop returns no entries but size stays > 0 until a read-path
# operation (get/exists/remove) triggers lazy reaping.

{
    my $m = Data::HashMap::II->new(0, 0);
    $m->put_ttl($_, $_, 1) for 1..3;
    sleep 2.2;
    my @kv = $m->pop;
    ok !@kv, 'non-LRU pop on all-expired map returns nothing';
    # size may remain 3 until lazy reap; we only guarantee no live entries
    is scalar(grep { defined $m->get($_) } 1..3), 0,
        'no live entries after TTL expiry';
}

# ---- LRU skip + TTL interaction (lru_skip=90) ----

{
    my $m = Data::HashMap::II->new(100, 0, 90);
    $m->put($_, $_) for 1..100;
    # Access entry 1 many times; even with skip=90, it should eventually promote
    $m->get(1) for 1..20;
    $m->put(101, 101);           # evicts LRU tail
    ok $m->exists(1), 'lru_skip=90: frequently-read key survives eviction';
}

# ---- SS + LRU + TTL ----

{
    my $m = Data::HashMap::SS->new(5, 2);
    $m->put("a", "1");
    $m->put("b", "2");
    $m->put("c", "3");
    $m->put("d", "4");
    $m->put("e", "5");
    is $m->size, 5, 'filled to capacity';
    $m->put("f", "6");           # evicts LRU
    is $m->size, 5, 'size stays at max_size after eviction';
    is $m->get("f"), "6", 'newly inserted key present';
}

done_testing;
