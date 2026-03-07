use strict;
use warnings;
use Test::More;
use Data::HashMap::I16;
use Data::HashMap::II;
use Data::HashMap::SI16;
use Data::HashMap::SS;
use Data::HashMap::SI;

# ---- Construction ----

{
    my $plain = Data::HashMap::II->new();
    is(hm_ii_ttl $plain, 0, 'plain map: ttl = 0');

    my $ttl = Data::HashMap::II->new(0, 5);
    is(hm_ii_max_size $ttl, 0, 'TTL map: max_size = 0');
    is(hm_ii_ttl $ttl, 5, 'TTL map: ttl = 5');

    my $both = Data::HashMap::II->new(100, 10);
    is(hm_ii_max_size $both, 100, 'LRU+TTL map: max_size = 100');
    is(hm_ii_ttl $both, 10, 'LRU+TTL map: ttl = 10');
}

# ---- TTL expiry via get ----

{
    my $m = Data::HashMap::II->new(0, 1);
    hm_ii_put $m, 42, 100;
    is(hm_ii_get $m, 42, 100, 'TTL: get before expiry returns value');
    ok(hm_ii_exists $m, 42, 'TTL: exists before expiry returns true');

    sleep 2;

    my $v = hm_ii_get $m, 42;
    ok(!defined $v, 'TTL: get after expiry returns undef');
    {
        my $e = hm_ii_exists $m, 42;
        ok(!$e, 'TTL: exists after expiry returns false');
    }
}

# ---- Expired entry is tombstoned (size decreases) ----

{
    my $m = Data::HashMap::II->new(0, 1);
    hm_ii_put $m, 1, 10;
    hm_ii_put $m, 2, 20;
    is(hm_ii_size $m, 2, 'TTL: size = 2 before expiry');

    sleep 2;

    # Trigger lazy expiry
    hm_ii_get $m, 1;
    hm_ii_get $m, 2;
    is(hm_ii_size $m, 0, 'TTL: size = 0 after expired gets');
}

# ---- Remove on expired entry returns false ----

{
    my $m = Data::HashMap::II->new(0, 1);
    hm_ii_put $m, 1, 10;
    ok(hm_ii_remove $m, 1, 'TTL: remove before expiry returns true');

    hm_ii_put $m, 2, 20;
    sleep 2;
    {
        my $r = hm_ii_remove $m, 2;
        ok(!$r, 'TTL: remove after expiry returns false');
    }
    is(hm_ii_size $m, 0, 'TTL: size = 0 after expired remove');
}

# ---- Non-expired entries returned normally ----

{
    my $m = Data::HashMap::II->new(0, 60);
    hm_ii_put $m, 1, 10;
    hm_ii_put $m, 2, 20;
    is(hm_ii_get $m, 1, 10, 'TTL 60s: non-expired get returns value');
    is(hm_ii_get $m, 2, 20, 'TTL 60s: non-expired get returns value');
}

# ---- Put refreshes TTL on update ----

{
    my $m = Data::HashMap::II->new(0, 2);
    hm_ii_put $m, 1, 10;
    sleep 1;
    # Re-put refreshes TTL
    hm_ii_put $m, 1, 20;
    sleep 1;
    # 2 seconds since original put, but only 1 since refresh
    is(hm_ii_get $m, 1, 20, 'TTL: put refresh keeps entry alive');
}

# ---- Iteration skips expired entries ----

{
    my $m = Data::HashMap::II->new(0, 1);
    hm_ii_put $m, 1, 10;
    hm_ii_put $m, 2, 20;

    my @k = sort { $a <=> $b } (hm_ii_keys $m);
    is_deeply(\@k, [1, 2], 'TTL iteration: before expiry, all keys');

    sleep 2;

    @k = hm_ii_keys $m;
    is(scalar(@k), 0, 'TTL iteration: after expiry, no keys');

    my @v = hm_ii_values $m;
    is(scalar(@v), 0, 'TTL iteration: after expiry, no values');

    my @items = hm_ii_items $m;
    is(scalar(@items), 0, 'TTL iteration: after expiry, no items');
}

# ---- Counter ops on expired key treat as new key ----

{
    my $m = Data::HashMap::II->new(0, 1);
    hm_ii_put $m, 1, 100;
    sleep 2;

    # incr on expired key should create new with value 1
    is(hm_ii_incr $m, 1, 1, 'TTL counter: incr on expired key returns 1 (new key)');
}

# ---- SS variant TTL ----

{
    my $m = Data::HashMap::SS->new(0, 1);
    hm_ss_put $m, "hello", "world";
    is(hm_ss_get $m, "hello", "world", 'SS TTL: before expiry');

    sleep 2;

    my $v = hm_ss_get $m, "hello";
    ok(!defined $v, 'SS TTL: after expiry returns undef');
}

# ---- SI variant TTL with counters ----

{
    my $m = Data::HashMap::SI->new(0, 1);
    hm_si_put $m, "x", 42;
    sleep 2;

    my $v = hm_si_get $m, "x";
    ok(!defined $v, 'SI TTL: expired get returns undef');

    is(hm_si_incr $m, "x", 1, 'SI TTL: incr on expired key returns 1');
}

# ---- I16 variant TTL with counters ----

{
    my $m = Data::HashMap::I16->new(0, 1);
    hm_i16_put $m, 1, 42;
    is(hm_i16_get $m, 1, 42, 'I16 TTL: before expiry');
    sleep 2;
    my $v = hm_i16_get $m, 1;
    ok(!defined $v, 'I16 TTL: after expiry returns undef');
    is(hm_i16_incr $m, 1, 1, 'I16 TTL: incr on expired key returns 1');
}

# ---- SI16 variant TTL with counters ----

{
    my $m = Data::HashMap::SI16->new(0, 1);
    hm_si16_put $m, "x", 42;
    sleep 2;
    my $v = hm_si16_get $m, "x";
    ok(!defined $v, 'SI16 TTL: expired get returns undef');
    is(hm_si16_incr $m, "x", 1, 'SI16 TTL: incr on expired key returns 1');
}

# ---- LRU + TTL combined ----

{
    my $m = Data::HashMap::II->new(5, 1);
    hm_ii_put $m, $_, $_ * 10 for 1..5;
    is(hm_ii_size $m, 5, 'LRU+TTL: at capacity');

    sleep 2;

    # All entries expired; get should return undef
    my $v = hm_ii_get $m, 1;
    ok(!defined $v, 'LRU+TTL: expired entry returns undef');

    # LRU eviction fires (evicts an already-expired tail entry), then inserts
    hm_ii_put $m, 10, 100;
    is(hm_ii_get $m, 10, 100, 'LRU+TTL: new insert after expiry works');
}

done_testing;
