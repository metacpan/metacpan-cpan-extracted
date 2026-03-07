use strict;
use warnings;
use Test::More;
use Data::HashMap::I16;
use Data::HashMap::I16S;
use Data::HashMap::II;
use Data::HashMap::SS;
use Data::HashMap::SI;
use Data::HashMap::I32;
use Data::HashMap::IS;
use Data::HashMap::I32S;
use Data::HashMap::SI16;
use Data::HashMap::SI32;

# ---- Construction ----

{
    my $plain = Data::HashMap::II->new();
    is(hm_ii_max_size $plain, 0, 'plain map: max_size = 0');
    is(hm_ii_ttl $plain, 0, 'plain map: ttl = 0');

    my $lru = Data::HashMap::II->new(5);
    is(hm_ii_max_size $lru, 5, 'LRU map: max_size = 5');
    is(hm_ii_ttl $lru, 0, 'LRU map: ttl = 0');
}

# ---- Basic eviction at capacity ----

{
    my $m = Data::HashMap::II->new(5);
    hm_ii_put $m, $_, $_ * 10 for 1..5;
    is(hm_ii_size $m, 5, 'at capacity: size = 5');

    hm_ii_put $m, 6, 60;
    is(hm_ii_size $m, 5, 'after insert beyond capacity: size stays 5');

    my $v1 = hm_ii_get $m, 1;
    ok(!defined $v1, 'oldest key (1) evicted');

    is(hm_ii_get $m, 6, 60, 'newest key (6) present');
    is(hm_ii_get $m, 2, 20, 'key 2 still present');
}

# ---- Get promotes to MRU ----

{
    my $m = Data::HashMap::II->new(5);
    hm_ii_put $m, $_, $_ * 10 for 1..5;

    # Access key 1 — should promote it to MRU
    hm_ii_get $m, 1;
    # Insert key 6 — should evict key 2 (now LRU), not key 1
    hm_ii_put $m, 6, 60;
    my $v1 = hm_ii_get $m, 1;
    ok(defined $v1, 'get promotes: key 1 still present');
    my $v2 = hm_ii_get $m, 2;
    ok(!defined $v2, 'get promotes: key 2 evicted (was LRU)');
}

# ---- Put update promotes to MRU ----

{
    my $m = Data::HashMap::II->new(5);
    hm_ii_put $m, $_, $_ * 10 for 1..5;

    # Update key 1 — should promote it
    hm_ii_put $m, 1, 100;
    hm_ii_put $m, 6, 60;
    my $v1 = hm_ii_get $m, 1;
    ok(defined $v1, 'put update promotes: key 1 still present');
    is($v1, 100, 'put update: value updated');
    my $v2 = hm_ii_get $m, 2;
    ok(!defined $v2, 'put update promotes: key 2 evicted');
}

# ---- Put update of non-tail key does NOT evict ----

{
    my $m = Data::HashMap::II->new(3);
    hm_ii_put $m, 1, 10;
    hm_ii_put $m, 2, 20;
    hm_ii_put $m, 3, 30;
    # Order: 3(MRU) -> 2 -> 1(LRU), size=3
    # Update key 3 (MRU) — should NOT evict key 1 (LRU)
    hm_ii_put $m, 3, 99;
    is(hm_ii_size $m, 3, 'update MRU key at cap: size stays 3');
    is(hm_ii_get $m, 1, 10, 'update MRU key at cap: LRU entry survives');
    is(hm_ii_get $m, 3, 99, 'update MRU key at cap: value updated');

    # Update middle key — should also NOT evict
    hm_ii_put $m, 1, 11;
    is(hm_ii_size $m, 3, 'update middle key at cap: size stays 3');
    is(hm_ii_get $m, 2, 20, 'update middle key at cap: other entries survive');
}

# ---- Remove shrinks size, allows more inserts ----

{
    my $m = Data::HashMap::II->new(5);
    hm_ii_put $m, $_, $_ * 10 for 1..5;
    hm_ii_remove $m, 3;
    is(hm_ii_size $m, 4, 'after remove: size = 4');

    hm_ii_put $m, 6, 60;
    is(hm_ii_size $m, 5, 'insert after remove: size = 5');
    hm_ii_put $m, 7, 70;
    is(hm_ii_size $m, 5, 'at capacity again: size = 5');
}

# ---- Remove sole LRU entry ----

{
    my $m = Data::HashMap::II->new(1);
    hm_ii_put $m, 1, 10;
    is(hm_ii_size $m, 1, 'sole LRU: size = 1');
    hm_ii_remove $m, 1;
    is(hm_ii_size $m, 0, 'sole LRU: size = 0 after remove');
    hm_ii_put $m, 2, 20;
    is(hm_ii_size $m, 1, 'sole LRU: can insert after removing sole entry');
    is(hm_ii_get $m, 2, 20, 'sole LRU: value correct');
}

# ---- Counter operations with LRU ----

{
    my $m = Data::HashMap::II->new(5);
    hm_ii_put $m, $_, 0 for 1..5;

    # incr existing key promotes it
    hm_ii_incr $m, 1;
    hm_ii_put $m, 6, 60;
    my $v1 = hm_ii_get $m, 1;
    ok(defined $v1, 'incr promotes: key 1 still present');
    my $v2 = hm_ii_get $m, 2;
    ok(!defined $v2, 'incr promotes: key 2 evicted');

    # incr new key at capacity evicts LRU
    is(hm_ii_incr $m, 100, 1, 'incr new key returns 1');
    is(hm_ii_size $m, 5, 'incr new key at cap: size stays 5');
}

# ---- keys/values/items on LRU map ----

{
    my $m = Data::HashMap::II->new(3);
    hm_ii_put $m, 10, 100;
    hm_ii_put $m, 20, 200;
    hm_ii_put $m, 30, 300;

    my @k = sort { $a <=> $b } (hm_ii_keys $m);
    is_deeply(\@k, [10, 20, 30], 'keys on LRU map');

    my @v = sort { $a <=> $b } (hm_ii_values $m);
    is_deeply(\@v, [100, 200, 300], 'values on LRU map');

    my @items = hm_ii_items $m;
    my %h;
    while (@items) {
        my ($k, $v) = splice @items, 0, 2;
        $h{$k} = $v;
    }
    is_deeply(\%h, {10 => 100, 20 => 200, 30 => 300}, 'items on LRU map');
}

# ---- SS variant LRU ----

{
    my $m = Data::HashMap::SS->new(3);
    hm_ss_put $m, "a", "A";
    hm_ss_put $m, "b", "B";
    hm_ss_put $m, "c", "C";
    is(hm_ss_size $m, 3, 'SS LRU: at capacity');

    hm_ss_put $m, "d", "D";
    is(hm_ss_size $m, 3, 'SS LRU: stays at capacity');
    my $va = hm_ss_get $m, "a";
    ok(!defined $va, 'SS LRU: oldest key evicted');
    is(hm_ss_get $m, "d", "D", 'SS LRU: newest key present');
}

# ---- SI variant LRU with counters ----

{
    my $m = Data::HashMap::SI->new(3);
    hm_si_put $m, "x", 1;
    hm_si_put $m, "y", 2;
    hm_si_put $m, "z", 3;

    hm_si_incr $m, "x";  # promote x
    hm_si_put $m, "w", 4;  # evict y
    my $vy = hm_si_get $m, "y";
    ok(!defined $vy, 'SI LRU: y evicted after x promoted');
    is(hm_si_get $m, "x", 2, 'SI LRU: x incremented and present');
}

# ---- I32 variant LRU ----

{
    my $m = Data::HashMap::I32->new(3);
    hm_i32_put $m, 1, 10;
    hm_i32_put $m, 2, 20;
    hm_i32_put $m, 3, 30;
    hm_i32_put $m, 4, 40;
    is(hm_i32_size $m, 3, 'I32 LRU: at capacity');
    my $v1 = hm_i32_get $m, 1;
    ok(!defined $v1, 'I32 LRU: oldest evicted');
}

# ---- IS variant LRU ----

{
    my $m = Data::HashMap::IS->new(2);
    hm_is_put $m, 1, "one";
    hm_is_put $m, 2, "two";
    hm_is_put $m, 3, "three";
    is(hm_is_size $m, 2, 'IS LRU: at capacity');
    my $v1 = hm_is_get $m, 1;
    ok(!defined $v1, 'IS LRU: oldest evicted');
    is(hm_is_get $m, 3, "three", 'IS LRU: newest present');
}

# ---- I32S variant LRU ----

{
    my $m = Data::HashMap::I32S->new(2);
    hm_i32s_put $m, 1, "one";
    hm_i32s_put $m, 2, "two";
    hm_i32s_put $m, 3, "three";
    is(hm_i32s_size $m, 2, 'I32S LRU: at capacity');
    my $v1 = hm_i32s_get $m, 1;
    ok(!defined $v1, 'I32S LRU: oldest evicted');
}

# ---- SI32 variant LRU ----

{
    my $m = Data::HashMap::SI32->new(2);
    hm_si32_put $m, "a", 1;
    hm_si32_put $m, "b", 2;
    hm_si32_put $m, "c", 3;
    is(hm_si32_size $m, 2, 'SI32 LRU: at capacity');
    my $va = hm_si32_get $m, "a";
    ok(!defined $va, 'SI32 LRU: oldest evicted');
}

# ---- Stress: insert 10x max_size ----

{
    my $cap = 100;
    my $m = Data::HashMap::II->new($cap);
    hm_ii_put $m, $_, $_ for 1..($cap * 10);
    is(hm_ii_size $m, $cap, "stress: size stays at $cap after 10x inserts");

    # Verify only the last $cap keys are present
    for my $k (($cap * 9 + 1)..($cap * 10)) {
        my $v = hm_ii_get $m, $k;
        ok(defined $v, "stress: recent key $k present");
    }
}

# ---- exists does NOT promote (read-only check) ----

{
    my $m = Data::HashMap::II->new(3);
    hm_ii_put $m, 1, 10;
    hm_ii_put $m, 2, 20;
    hm_ii_put $m, 3, 30;
    ok(hm_ii_exists $m, 1, 'exists on LRU: key 1 present');

    # exists should NOT promote key 1 — it should remain LRU
    hm_ii_exists $m, 1;
    hm_ii_put $m, 4, 40;  # should evict key 1 (still LRU), not key 2
    {
        my $e = hm_ii_exists $m, 1;
        ok(!$e, 'exists does not promote: key 1 evicted');
    }
    ok(hm_ii_exists $m, 2, 'exists does not promote: key 2 survived');
    ok(hm_ii_exists $m, 4, 'exists on LRU: key 4 present');
}

# ---- LRU + remove + reinsert preserves order through rehash ----

{
    my $m = Data::HashMap::II->new(8);
    hm_ii_put $m, $_, $_ * 10 for 1..8;

    # Remove several to create tombstones, then insert to force rehash
    hm_ii_remove $m, 2;
    hm_ii_remove $m, 4;
    hm_ii_remove $m, 6;
    is(hm_ii_size $m, 5, 'rehash LRU: size after removes');

    # Insert new keys — fills up, may trigger compact/rehash
    hm_ii_put $m, 10, 100;
    hm_ii_put $m, 11, 110;
    hm_ii_put $m, 12, 120;
    is(hm_ii_size $m, 8, 'rehash LRU: back at capacity');

    # Insert one more — should evict key 1 (LRU after remove+reinsert)
    hm_ii_put $m, 13, 130;
    is(hm_ii_size $m, 8, 'rehash LRU: stays at capacity after eviction');
    my $v1 = hm_ii_get $m, 1;
    ok(!defined $v1, 'rehash LRU: key 1 (oldest) evicted');
    is(hm_ii_get $m, 13, 130, 'rehash LRU: newest key present');
}

# ---- I16 variant LRU ----

{
    my $m = Data::HashMap::I16->new(3);
    hm_i16_put $m, 1, 10;
    hm_i16_put $m, 2, 20;
    hm_i16_put $m, 3, 30;
    hm_i16_put $m, 4, 40;
    is(hm_i16_size $m, 3, 'I16 LRU: at capacity');
    my $v1 = hm_i16_get $m, 1;
    ok(!defined $v1, 'I16 LRU: oldest evicted');
}

# ---- I16S variant LRU ----

{
    my $m = Data::HashMap::I16S->new(2);
    hm_i16s_put $m, 1, "one";
    hm_i16s_put $m, 2, "two";
    hm_i16s_put $m, 3, "three";
    is(hm_i16s_size $m, 2, 'I16S LRU: at capacity');
    my $v1 = hm_i16s_get $m, 1;
    ok(!defined $v1, 'I16S LRU: oldest evicted');
}

# ---- SI16 variant LRU with counters ----

{
    my $m = Data::HashMap::SI16->new(3);
    hm_si16_put $m, "x", 1;
    hm_si16_put $m, "y", 2;
    hm_si16_put $m, "z", 3;

    hm_si16_incr $m, "x";  # promote x
    hm_si16_put $m, "w", 4;  # evict y
    my $vy = hm_si16_get $m, "y";
    ok(!defined $vy, 'SI16 LRU: y evicted after x promoted');
    is(hm_si16_get $m, "x", 2, 'SI16 LRU: x incremented and present');
}

# ---- LRU capacity does not grow unboundedly ----

{
    my $cap = 16;
    my $m = Data::HashMap::II->new($cap);
    # Steady-state insert/evict cycle: each insert evicts the LRU tail
    hm_ii_put $m, $_, $_ for 1..($cap * 100);
    is(hm_ii_size $m, $cap, 'capacity stability: size stays at cap');

    # Verify all expected keys present (last $cap keys)
    my @k = sort { $a <=> $b } (hm_ii_keys $m);
    is(scalar @k, $cap, 'capacity stability: correct key count');
    is($k[0], $cap * 100 - $cap + 1, 'capacity stability: oldest surviving key');
    is($k[-1], $cap * 100, 'capacity stability: newest key');
}

done_testing;
