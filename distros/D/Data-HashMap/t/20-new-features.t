use strict;
use warnings;
use Test::More;

use Data::HashMap::I16;
use Data::HashMap::I16S;
use Data::HashMap::SI16;
use Data::HashMap::I32;
use Data::HashMap::I32S;
use Data::HashMap::SI32;
use Data::HashMap::II;
use Data::HashMap::IS;
use Data::HashMap::SI;
use Data::HashMap::SS;
use Data::HashMap::IA;
use Data::HashMap::SA;
use Data::HashMap::I32A;
use Data::HashMap::I16A;

# Helper: wrap keyword calls that would otherwise eat is()'s extra args
# Keywords use XPK_TERMEXPR which consumes subsequent comma-separated args,
# so we assign to a variable first.

# ============================================================
# clear
# ============================================================

# keyword clear - int/int
{
    my $m = Data::HashMap::II->new();
    hm_ii_put $m, 1, 10;
    hm_ii_put $m, 2, 20;
    my $s = hm_ii_size $m;
    is($s, 2, 'II size before clear');
    hm_ii_clear $m;
    $s = hm_ii_size $m;
    is($s, 0, 'II size after clear');
    my $v = hm_ii_get $m, 1;
    is($v, undef, 'II get after clear');
    hm_ii_put $m, 3, 30;
    $v = hm_ii_get $m, 3;
    is($v, 30, 'II put after clear');
}

# keyword clear - string/string
{
    my $m = Data::HashMap::SS->new();
    hm_ss_put $m, "a", "b";
    hm_ss_clear $m;
    my $s = hm_ss_size $m;
    is($s, 0, 'SS size after clear');
    my $v = hm_ss_get $m, "a";
    is($v, undef, 'SS get after clear');
}

# keyword clear - int/SV*
{
    my $m = Data::HashMap::IA->new();
    hm_ia_put $m, 1, [1,2,3];
    hm_ia_clear $m;
    my $s = hm_ia_size $m;
    is($s, 0, 'IA size after clear');
}

# keyword clear - string/SV*
{
    my $m = Data::HashMap::SA->new();
    hm_sa_put $m, "x", {a => 1};
    hm_sa_clear $m;
    my $s = hm_sa_size $m;
    is($s, 0, 'SA size after clear');
}

# method clear
{
    my $m = Data::HashMap::I32->new();
    $m->put(1, 10);
    $m->clear();
    is($m->size(), 0, 'I32 method clear');
}

# clear with LRU
{
    my $m = Data::HashMap::II->new(5);
    hm_ii_put $m, 1, 10;
    hm_ii_put $m, 2, 20;
    hm_ii_clear $m;
    my $s = hm_ii_size $m;
    is($s, 0, 'II LRU clear size');
    hm_ii_put $m, 3, 30;
    my $v = hm_ii_get $m, 3;
    is($v, 30, 'II LRU put after clear');
}

# clear with TTL
{
    my $m = Data::HashMap::II->new(0, 60);
    hm_ii_put $m, 1, 10;
    hm_ii_clear $m;
    my $s = hm_ii_size $m;
    is($s, 0, 'II TTL clear size');
}

# clear resets each iterator
{
    my $m = Data::HashMap::II->new();
    hm_ii_put $m, 1, 10;
    hm_ii_put $m, 2, 20;
    my ($k, $v) = hm_ii_each $m;
    ok(defined $k, 'II each before clear returns');
    hm_ii_clear $m;
    hm_ii_put $m, 5, 50;
    my %seen;
    while (my ($ek, $ev) = hm_ii_each $m) {
        $seen{$ek} = $ev;
    }
    is_deeply(\%seen, {5 => 50}, 'II each after clear sees new entries');
}

# ============================================================
# to_hash
# ============================================================

# keyword to_hash - int/int
{
    my $m = Data::HashMap::II->new();
    hm_ii_put $m, 1, 10;
    hm_ii_put $m, 2, 20;
    my $h = hm_ii_to_hash $m;
    is(ref $h, 'HASH', 'II to_hash returns hashref');
    is($h->{1}, 10, 'II to_hash key 1');
    is($h->{2}, 20, 'II to_hash key 2');
    is(scalar keys %$h, 2, 'II to_hash size');
}

# keyword to_hash - string/string
{
    my $m = Data::HashMap::SS->new();
    hm_ss_put $m, "foo", "bar";
    hm_ss_put $m, "baz", "qux";
    my $h = hm_ss_to_hash $m;
    is($h->{foo}, "bar", 'SS to_hash');
    is($h->{baz}, "qux", 'SS to_hash 2');
}

# keyword to_hash - int/string
{
    my $m = Data::HashMap::IS->new();
    hm_is_put $m, 42, "hello";
    my $h = hm_is_to_hash $m;
    is($h->{42}, "hello", 'IS to_hash');
}

# keyword to_hash - string/int
{
    my $m = Data::HashMap::SI->new();
    hm_si_put $m, "abc", 99;
    my $h = hm_si_to_hash $m;
    is($h->{abc}, 99, 'SI to_hash');
}

# keyword to_hash - int/SV*
{
    my $m = Data::HashMap::IA->new();
    hm_ia_put $m, 1, [10, 20];
    my $h = hm_ia_to_hash $m;
    is_deeply($h->{1}, [10, 20], 'IA to_hash');
}

# keyword to_hash - string/SV*
{
    my $m = Data::HashMap::SA->new();
    hm_sa_put $m, "k", {x => 1};
    my $h = hm_sa_to_hash $m;
    is_deeply($h->{k}, {x => 1}, 'SA to_hash');
}

# to_hash - empty map
{
    my $m = Data::HashMap::II->new();
    my $h = hm_ii_to_hash $m;
    is_deeply($h, {}, 'II to_hash empty');
}

# to_hash - skips expired TTL entries
{
    my $m = Data::HashMap::II->new(0, 1);
    hm_ii_put $m, 1, 10;
    hm_ii_put $m, 2, 20;
    sleep 2;
    my $h = hm_ii_to_hash $m;
    is_deeply($h, {}, 'II to_hash skips expired');
}

# method to_hash
{
    my $m = Data::HashMap::I32->new();
    $m->put(5, 50);
    my $h = $m->to_hash();
    is($h->{5}, 50, 'I32 method to_hash');
}

# to_hash with i16 variants
{
    my $m = Data::HashMap::I16->new();
    hm_i16_put $m, 1, 100;
    my $h = hm_i16_to_hash $m;
    is($h->{1}, 100, 'I16 to_hash');
}

{
    my $m = Data::HashMap::SI16->new();
    hm_si16_put $m, "x", 42;
    my $h = hm_si16_to_hash $m;
    is($h->{x}, 42, 'SI16 to_hash');
}

# to_hash - UTF-8 keys and values
{
    my $m = Data::HashMap::SS->new();
    my $key = "\x{263A}";
    my $val = "\x{2603}";
    hm_ss_put $m, $key, $val;
    my $h = hm_ss_to_hash $m;
    is($h->{$key}, $val, 'SS to_hash UTF-8');
    ok(utf8::is_utf8((keys %$h)[0]), 'SS to_hash UTF-8 key flag');
}

# ============================================================
# put_ttl (per-key TTL)
# ============================================================

# keyword put_ttl - entry expires independently
{
    my $m = Data::HashMap::II->new();
    hm_ii_put_ttl $m, 1, 10, 1;
    hm_ii_put $m, 2, 20;
    my $v1 = hm_ii_get $m, 1;
    is($v1, 10, 'II put_ttl before expiry');
    my $v2 = hm_ii_get $m, 2;
    is($v2, 20, 'II no-ttl before expiry');
    sleep 2;
    $v1 = hm_ii_get $m, 1;
    is($v1, undef, 'II put_ttl expired');
    $v2 = hm_ii_get $m, 2;
    is($v2, 20, 'II no-ttl survives');
}

# keyword put_ttl - string/string
{
    my $m = Data::HashMap::SS->new();
    hm_ss_put_ttl $m, "a", "b", 1;
    hm_ss_put $m, "c", "d";
    sleep 2;
    my $v1 = hm_ss_get $m, "a";
    is($v1, undef, 'SS put_ttl expired');
    my $v2 = hm_ss_get $m, "c";
    is($v2, "d", 'SS no-ttl survives');
}

# keyword put_ttl - int/SV*
{
    my $m = Data::HashMap::IA->new();
    hm_ia_put_ttl $m, 1, [1], 1;
    sleep 2;
    my $v = hm_ia_get $m, 1;
    is($v, undef, 'IA put_ttl expired');
}

# keyword put_ttl - string/SV*
{
    my $m = Data::HashMap::SA->new();
    hm_sa_put_ttl $m, "k", {a=>1}, 1;
    sleep 2;
    my $v = hm_sa_get $m, "k";
    is($v, undef, 'SA put_ttl expired');
}

# put_ttl on map with default_ttl - per-key overrides default
{
    my $m = Data::HashMap::II->new(0, 60);
    hm_ii_put_ttl $m, 1, 10, 1;
    hm_ii_put $m, 2, 20;
    sleep 2;
    my $v1 = hm_ii_get $m, 1;
    is($v1, undef, 'II put_ttl overrides default TTL (expired)');
    my $v2 = hm_ii_get $m, 2;
    is($v2, 20, 'II default TTL still alive');
}

# put_ttl with LRU
{
    my $m = Data::HashMap::II->new(10);
    hm_ii_put_ttl $m, 1, 10, 1;
    sleep 2;
    my $v = hm_ii_get $m, 1;
    is($v, undef, 'II put_ttl with LRU expired');
}

# method put_ttl
{
    my $m = Data::HashMap::I32->new();
    $m->put_ttl(1, 10, 1);
    is($m->get(1), 10, 'I32 method put_ttl before expiry');
    sleep 2;
    is($m->get(1), undef, 'I32 method put_ttl expired');
}

# to_hash skips put_ttl expired entries
{
    my $m = Data::HashMap::II->new();
    hm_ii_put_ttl $m, 1, 10, 1;
    hm_ii_put $m, 2, 20;
    sleep 2;
    my $h = hm_ii_to_hash $m;
    is_deeply($h, {2 => 20}, 'II to_hash skips put_ttl expired');
}

# ============================================================
# get_or_set
# ============================================================

# keyword get_or_set - inserts if missing
{
    my $m = Data::HashMap::II->new();
    my $v = hm_ii_get_or_set $m, 1, 42;
    is($v, 42, 'II get_or_set inserts default');
    my $v2 = hm_ii_get $m, 1;
    is($v2, 42, 'II get_or_set value stored');
}

# keyword get_or_set - returns existing
{
    my $m = Data::HashMap::II->new();
    hm_ii_put $m, 1, 10;
    my $v = hm_ii_get_or_set $m, 1, 99;
    is($v, 10, 'II get_or_set returns existing');
    my $v2 = hm_ii_get $m, 1;
    is($v2, 10, 'II get_or_set does not overwrite');
}

# keyword get_or_set - string/string
{
    my $m = Data::HashMap::SS->new();
    my $v = hm_ss_get_or_set $m, "k", "default";
    is($v, "default", 'SS get_or_set inserts');
    my $v2 = hm_ss_get_or_set $m, "k", "other";
    is($v2, "default", 'SS get_or_set returns existing');
}

# keyword get_or_set - string/int
{
    my $m = Data::HashMap::SI->new();
    my $v = hm_si_get_or_set $m, "x", 7;
    is($v, 7, 'SI get_or_set inserts');
    my $v2 = hm_si_get_or_set $m, "x", 99;
    is($v2, 7, 'SI get_or_set returns existing');
}

# keyword get_or_set - int/string
{
    my $m = Data::HashMap::IS->new();
    my $v = hm_is_get_or_set $m, 1, "hello";
    is($v, "hello", 'IS get_or_set inserts');
    my $v2 = hm_is_get_or_set $m, 1, "world";
    is($v2, "hello", 'IS get_or_set returns existing');
}

# keyword get_or_set - int/SV*
{
    my $m = Data::HashMap::IA->new();
    my $v = hm_ia_get_or_set $m, 1, [10, 20];
    is_deeply($v, [10, 20], 'IA get_or_set inserts');
    my $v2 = hm_ia_get_or_set $m, 1, [99];
    is_deeply($v2, [10, 20], 'IA get_or_set returns existing');
}

# keyword get_or_set - string/SV*
{
    my $m = Data::HashMap::SA->new();
    my $v = hm_sa_get_or_set $m, "k", {a => 1};
    is_deeply($v, {a => 1}, 'SA get_or_set inserts');
    my $v2 = hm_sa_get_or_set $m, "k", {b => 2};
    is_deeply($v2, {a => 1}, 'SA get_or_set returns existing');
}

# method get_or_set
{
    my $m = Data::HashMap::I32->new();
    my $v = $m->get_or_set(5, 50);
    is($v, 50, 'I32 method get_or_set inserts');
    my $v2 = $m->get_or_set(5, 99);
    is($v2, 50, 'I32 method get_or_set returns existing');
}

# get_or_set does not affect size when key exists
{
    my $m = Data::HashMap::II->new();
    hm_ii_put $m, 1, 10;
    hm_ii_get_or_set $m, 1, 99;
    my $s = hm_ii_size $m;
    is($s, 1, 'II get_or_set no extra entry');
}

# ============================================================
# i16 variants - clear/to_hash/put_ttl/get_or_set
# ============================================================

{
    my $m = Data::HashMap::I16->new();
    hm_i16_put $m, 1, 10;
    hm_i16_clear $m;
    my $s = hm_i16_size $m;
    is($s, 0, 'I16 clear');

    hm_i16_put $m, 2, 20;
    my $v = hm_i16_get_or_set $m, 2, 99;
    is($v, 20, 'I16 get_or_set existing');
    my $v2 = hm_i16_get_or_set $m, 3, 30;
    is($v2, 30, 'I16 get_or_set new');
}

{
    my $m = Data::HashMap::I16S->new();
    hm_i16s_put $m, 1, "a";
    hm_i16s_clear $m;
    my $s = hm_i16s_size $m;
    is($s, 0, 'I16S clear');

    my $v = hm_i16s_get_or_set $m, 1, "b";
    is($v, "b", 'I16S get_or_set new');
}

{
    my $m = Data::HashMap::I16A->new();
    hm_i16a_put $m, 1, [1];
    hm_i16a_clear $m;
    my $s = hm_i16a_size $m;
    is($s, 0, 'I16A clear');
}

# ============================================================
# i32 variants - clear/to_hash/put_ttl/get_or_set
# ============================================================

{
    my $m = Data::HashMap::I32S->new();
    hm_i32s_put $m, 1, "x";
    my $h = hm_i32s_to_hash $m;
    is($h->{1}, "x", 'I32S to_hash');
    hm_i32s_clear $m;
    my $s = hm_i32s_size $m;
    is($s, 0, 'I32S clear');
}

{
    my $m = Data::HashMap::SI32->new();
    hm_si32_put $m, "a", 10;
    my $h = hm_si32_to_hash $m;
    is($h->{a}, 10, 'SI32 to_hash');
    my $v = hm_si32_get_or_set $m, "b", 20;
    is($v, 20, 'SI32 get_or_set new');
}

{
    my $m = Data::HashMap::I32A->new();
    hm_i32a_put $m, 1, "hello";
    my $h = hm_i32a_to_hash $m;
    is($h->{1}, "hello", 'I32A to_hash');
    hm_i32a_clear $m;
    my $s = hm_i32a_size $m;
    is($s, 0, 'I32A clear');
}

# ============================================================
# counter ops on new keys
# ============================================================

{
    my $m = Data::HashMap::II->new();
    my $v = hm_ii_decr $m, 1;
    is($v, -1, 'II decr on new key returns -1');
}

{
    my $m = Data::HashMap::II->new();
    my $v = hm_ii_incr_by $m, 1, 5;
    is($v, 5, 'II incr_by 5 on new key returns 5');
}

{
    my $m = Data::HashMap::SI->new();
    my $v = hm_si_decr $m, "x";
    is($v, -1, 'SI decr on new key returns -1');
}

# ============================================================
# put_ttl with ttl=0 (no expiry)
# ============================================================

{
    my $m = Data::HashMap::II->new(0, 60);
    hm_ii_put_ttl $m, 1, 10, 0;  # ttl=0 should use default (60s)
    my $v = hm_ii_get $m, 1;
    is($v, 10, 'II put_ttl ttl=0 uses default TTL');
}

# ============================================================
# incr preserves per-key TTL on map without default_ttl
# ============================================================

{
    my $m = Data::HashMap::II->new();
    hm_ii_put_ttl $m, 1, 10, 1;
    hm_ii_incr $m, 1;
    my $v = hm_ii_get $m, 1;
    is($v, 11, 'II incr after put_ttl returns incremented');
    sleep 2;
    $v = hm_ii_get $m, 1;
    is($v, undef, 'II incr did not clobber per-key TTL');
}

# incr on TTL map refreshes expiry to default_ttl
{
    my $m = Data::HashMap::II->new(0, 3);
    hm_ii_put $m, 1, 10;
    sleep 2;
    hm_ii_incr $m, 1;  # refreshes TTL to default_ttl (3s from now)
    sleep 2;
    my $v = hm_ii_get $m, 1;
    is($v, 11, 'II incr refreshes TTL on default_ttl map');
}

# ============================================================
# sentinel key rejection for get_or_set
# ============================================================

{
    my $m = Data::HashMap::I32->new();
    my $v = $m->get_or_set(-2147483648, 99);
    is($v, undef, 'I32 get_or_set rejects INT32_MIN');
}

{
    my $m = Data::HashMap::I16->new();
    my $v = hm_i16_get_or_set $m, -32768, 99;
    is($v, undef, 'I16 get_or_set rejects INT16_MIN');
}

# ============================================================
# get_or_set re-inserts after put_ttl expiry
# ============================================================

{
    my $m = Data::HashMap::II->new();
    hm_ii_put_ttl $m, 1, 10, 1;
    sleep 2;
    my $v = hm_ii_get_or_set $m, 1, 42;
    is($v, 42, 'II get_or_set re-inserts after put_ttl expiry');
    my $v2 = hm_ii_get $m, 1;
    is($v2, 42, 'II get_or_set stored value after expiry');
}

# get_or_set on TTL-enabled map — inserted value expires
{
    my $m = Data::HashMap::II->new(0, 1);
    my $v = hm_ii_get_or_set $m, 1, 10;
    is($v, 10, 'II get_or_set on TTL map inserts');
    sleep 2;
    $v = hm_ii_get $m, 1;
    is($v, undef, 'II get_or_set inserted value expires with default TTL');
}

# plain put after put_ttl clears stale per-key TTL
{
    my $m = Data::HashMap::II->new();
    hm_ii_put_ttl $m, 1, 10, 1;
    hm_ii_put $m, 1, 99;        # plain put should clear TTL
    sleep 2;
    my $v = hm_ii_get $m, 1;
    is($v, 99, 'II plain put after put_ttl clears stale TTL');
}

{
    my $m = Data::HashMap::SS->new();
    hm_ss_put_ttl $m, "k", "old", 1;
    hm_ss_put $m, "k", "new";
    sleep 2;
    my $v = hm_ss_get $m, "k";
    is($v, "new", 'SS plain put after put_ttl clears stale TTL');
}

# get_or_set with LRU — eviction works
{
    my $m = Data::HashMap::II->new(3);
    hm_ii_get_or_set $m, 1, 10;
    hm_ii_get_or_set $m, 2, 20;
    hm_ii_get_or_set $m, 3, 30;
    hm_ii_get_or_set $m, 4, 40;
    my $v = hm_ii_get $m, 1;
    is($v, undef, 'II get_or_set with LRU evicts oldest');
    my $s = hm_ii_size $m;
    is($s, 3, 'II get_or_set LRU size capped');
}

# ============================================================
# incr/decr overflow boundaries
# ============================================================

# II incr at INT64_MAX (croak on overflow)
{
    my $m = Data::HashMap::II->new();
    hm_ii_put $m, 1, 9223372036854775806;  # INT64_MAX - 1
    my $v = hm_ii_incr $m, 1;
    is($v, 9223372036854775807, 'II incr to INT64_MAX');
    eval { hm_ii_incr $m, 1 };
    like($@, qr/increment failed/, 'II incr past INT64_MAX croaks');
    $v = hm_ii_get $m, 1;
    is($v, 9223372036854775807, 'II value unchanged after overflow');
}

# I32 decr at INT32_MIN (croak on underflow)
{
    my $m = Data::HashMap::I32->new();
    hm_i32_put $m, 1, -2147483647;  # INT32_MIN + 1
    my $v = hm_i32_decr $m, 1;
    is($v, -2147483648, 'I32 decr to INT32_MIN');
    eval { hm_i32_decr $m, 1 };
    like($@, qr/decrement failed/, 'I32 decr past INT32_MIN croaks');
}

# I16 incr at INT16_MAX (croak on overflow)
{
    my $m = Data::HashMap::I16->new();
    hm_i16_put $m, 1, 32766;  # INT16_MAX - 1
    my $v = hm_i16_incr $m, 1;
    is($v, 32767, 'I16 incr to INT16_MAX');
    eval { hm_i16_incr $m, 1 };
    like($@, qr/increment failed/, 'I16 incr past INT16_MAX croaks');
}

# SI decr at INT64_MIN (croak on underflow)
{
    my $m = Data::HashMap::SI->new();
    hm_si_put $m, "x", -9223372036854775807;  # INT64_MIN + 1
    my $v = hm_si_decr $m, "x";
    my $int64_min = -9223372036854775807 - 1;
    is($v, $int64_min, 'SI decr to INT64_MIN');
    eval { hm_si_decr $m, "x" };
    like($@, qr/decrement failed/, 'SI decr past INT64_MIN croaks');
}

# ============================================================
# put_ttl for SI16/SI32 variants
# ============================================================

{
    my $m = Data::HashMap::SI16->new();
    hm_si16_put_ttl $m, "k", 42, 1;
    my $v = hm_si16_get $m, "k";
    is($v, 42, 'SI16 put_ttl before expiry');
    sleep 2;
    $v = hm_si16_get $m, "k";
    is($v, undef, 'SI16 put_ttl expired');
}

{
    my $m = Data::HashMap::SI32->new();
    hm_si32_put_ttl $m, "k", 100, 1;
    my $v = hm_si32_get $m, "k";
    is($v, 100, 'SI32 put_ttl before expiry');
    sleep 2;
    $v = hm_si32_get $m, "k";
    is($v, undef, 'SI32 put_ttl expired');
}

# ============================================================
# get_or_set + TTL expiry for SV* variants
# ============================================================

{
    my $m = Data::HashMap::IA->new(0, 1);
    my $v = hm_ia_get_or_set $m, 1, [10];
    is_deeply($v, [10], 'IA get_or_set on TTL map inserts');
    sleep 2;
    my $v2 = hm_ia_get_or_set $m, 1, [20];
    is_deeply($v2, [20], 'IA get_or_set re-inserts after TTL expiry');
}

{
    my $m = Data::HashMap::SA->new(0, 1);
    my $v = hm_sa_get_or_set $m, "k", {a=>1};
    is_deeply($v, {a=>1}, 'SA get_or_set on TTL map inserts');
    sleep 2;
    my $v2 = hm_sa_get_or_set $m, "k", {b=>2};
    is_deeply($v2, {b=>2}, 'SA get_or_set re-inserts after TTL expiry');
}

{
    my $m = Data::HashMap::I32A->new(0, 1);
    my $v = hm_i32a_get_or_set $m, 1, "first";
    is($v, "first", 'I32A get_or_set on TTL map inserts');
    sleep 2;
    my $v2 = hm_i32a_get_or_set $m, 1, "second";
    is($v2, "second", 'I32A get_or_set re-inserts after TTL expiry');
}

{
    my $m = Data::HashMap::I16A->new(0, 1);
    my $v = hm_i16a_get_or_set $m, 1, "first";
    is($v, "first", 'I16A get_or_set on TTL map inserts');
    sleep 2;
    my $v2 = hm_i16a_get_or_set $m, 1, "second";
    is($v2, "second", 'I16A get_or_set re-inserts after TTL expiry');
}

# ============================================================
# size vs keys count after TTL expiry
# ============================================================

# size includes expired-not-yet-reaped entries, keys skips them
{
    my $m = Data::HashMap::II->new(0, 1);
    hm_ii_put $m, 1, 10;
    hm_ii_put $m, 2, 20;
    sleep 2;
    my $size = hm_ii_size $m;
    my @keys = hm_ii_keys $m;
    # size still reports 2 (expired but not reaped)
    # keys returns 0 (skips expired)
    is(scalar @keys, 0, 'II keys skips expired entries');
    # after get, expired entries are reaped
    hm_ii_get $m, 1;
    hm_ii_get $m, 2;
    my $size_after = hm_ii_size $m;
    is($size_after, 0, 'II size drops after expired entries are reaped');
}

# ============================================================
# get_direct (zero-copy get for string-value variants)
# ============================================================

# SS get_direct - basic
{
    my $m = Data::HashMap::SS->new();
    hm_ss_put $m, "foo", "bar";
    my $v = hm_ss_get_direct $m, "foo";
    is($v, "bar", 'SS get_direct returns value');
}

# SS get_direct - missing key
{
    my $m = Data::HashMap::SS->new();
    my $v = hm_ss_get_direct $m, "nope";
    is($v, undef, 'SS get_direct returns undef for missing key');
}

# SS get_direct - UTF-8
{
    my $m = Data::HashMap::SS->new();
    my $val = "\x{263A}";
    hm_ss_put $m, "k", $val;
    my $v = hm_ss_get_direct $m, "k";
    is($v, $val, 'SS get_direct UTF-8 value');
    ok(utf8::is_utf8($v), 'SS get_direct preserves UTF-8 flag');
}

# IS get_direct - basic
{
    my $m = Data::HashMap::IS->new();
    hm_is_put $m, 42, "hello";
    my $v = hm_is_get_direct $m, 42;
    is($v, "hello", 'IS get_direct returns value');
}

# IS get_direct - missing key
{
    my $m = Data::HashMap::IS->new();
    my $v = hm_is_get_direct $m, 99;
    is($v, undef, 'IS get_direct returns undef for missing key');
}

# I32S get_direct - basic
{
    my $m = Data::HashMap::I32S->new();
    hm_i32s_put $m, 1, "world";
    my $v = hm_i32s_get_direct $m, 1;
    is($v, "world", 'I32S get_direct returns value');
}

# I16S get_direct - basic
{
    my $m = Data::HashMap::I16S->new();
    hm_i16s_put $m, 1, "test";
    my $v = hm_i16s_get_direct $m, 1;
    is($v, "test", 'I16S get_direct returns value');
}

# I16S get_direct - missing key
{
    my $m = Data::HashMap::I16S->new();
    my $v = hm_i16s_get_direct $m, 99;
    is($v, undef, 'I16S get_direct returns undef for missing key');
}

# IS get_direct - TTL expiry
{
    my $m = Data::HashMap::IS->new(0, 1);
    hm_is_put $m, 1, "ttl_val";
    my $v = hm_is_get_direct $m, 1;
    is($v, "ttl_val", 'IS get_direct before TTL expiry');
    sleep 2;
    $v = hm_is_get_direct $m, 1;
    is($v, undef, 'IS get_direct returns undef after TTL expiry');
}

# method get_direct
{
    my $m = Data::HashMap::SS->new();
    hm_ss_put $m, "k", "v";
    my $v = $m->get_direct("k");
    is($v, "v", 'SS method get_direct');
}

# ============================================================
# take (remove + return value)
# ============================================================

# int key, int value
{
    my $m = Data::HashMap::II->new();
    hm_ii_put $m, 1, 42;
    is(hm_ii_take $m, 1, 42, 'II take returns value');
    is(hm_ii_size $m, 0, 'II take removes entry');
    is(hm_ii_take $m, 1, undef, 'II take missing returns undef');
}

# int key, string value
{
    my $m = Data::HashMap::IS->new();
    hm_is_put $m, 1, "hello";
    is(hm_is_take $m, 1, "hello", 'IS take returns string');
    is(hm_is_size $m, 0, 'IS take removes entry');
}

# string key, string value
{
    my $m = Data::HashMap::SS->new();
    hm_ss_put $m, "k", "v";
    is(hm_ss_take $m, "k", "v", 'SS take returns string');
    is(hm_ss_size $m, 0, 'SS take removes entry');
}

# string key, int value
{
    my $m = Data::HashMap::SI->new();
    hm_si_put $m, "k", 99;
    is(hm_si_take $m, "k", 99, 'SI take returns int');
    is(hm_si_size $m, 0, 'SI take removes entry');
}

# int key, SV* value
{
    my $m = Data::HashMap::IA->new();
    hm_ia_put $m, 1, [1,2,3];
    my $v = hm_ia_take $m, 1;
    is_deeply($v, [1,2,3], 'IA take returns arrayref');
    is(hm_ia_size $m, 0, 'IA take removes entry');
    is(hm_ia_take $m, 1, undef, 'IA take missing returns undef');
}

# string key, SV* value
{
    my $m = Data::HashMap::SA->new();
    hm_sa_put $m, "k", {a => 1};
    my $v = hm_sa_take $m, "k";
    is_deeply($v, {a => 1}, 'SA take returns hashref');
    is(hm_sa_size $m, 0, 'SA take removes entry');
}

# take on expired TTL entry returns undef
{
    my $m = Data::HashMap::II->new(0, 1);
    hm_ii_put $m, 1, 42;
    sleep 2;
    is(hm_ii_take $m, 1, undef, 'II take on expired entry returns undef');
}

# I16/I32 variants
{
    my $m = Data::HashMap::I32->new();
    hm_i32_put $m, 1, 99;
    is(hm_i32_take $m, 1, 99, 'I32 take');

    my $m2 = Data::HashMap::I16->new();
    hm_i16_put $m2, 1, 42;
    is(hm_i16_take $m2, 1, 42, 'I16 take');
}

# ============================================================
# drain (batch remove + return)
# ============================================================

{
    my $m = Data::HashMap::II->new();
    hm_ii_put $m, $_, $_ * 10 for 1..10;
    my @batch = hm_ii_drain $m, 3;
    is(scalar @batch, 6, 'II drain: 3 pairs = 6 elements');
    is(hm_ii_size $m, 7, 'II drain: 7 remain');

    my @rest = hm_ii_drain $m, 100;
    is(scalar @rest, 14, 'II drain: rest = 7 pairs');
    is(hm_ii_size $m, 0, 'II drain: empty');

    my @empty = hm_ii_drain $m, 5;
    is(scalar @empty, 0, 'II drain empty map');
}

{
    my $m = Data::HashMap::SS->new();
    hm_ss_put $m, "k$_", "v$_" for 1..5;
    my @pairs = hm_ss_drain $m, 2;
    is(scalar @pairs, 4, 'SS drain: 2 pairs');
    is(hm_ss_size $m, 3, 'SS drain: 3 remain');
}

{
    my $m = Data::HashMap::IA->new();
    hm_ia_put $m, $_, [$_] for 1..3;
    my @pairs = hm_ia_drain $m, 2;
    is(scalar @pairs, 4, 'IA drain: 2 pairs');
    is(hm_ia_size $m, 1, 'IA drain: 1 remains');
    is_deeply($pairs[1], [$pairs[0]], 'IA drain: value intact');
}

# drain respects TTL
{
    my $m = Data::HashMap::II->new(0, 1);
    hm_ii_put $m, $_, $_ for 1..5;
    sleep 2;
    hm_ii_put $m, 6, 6;  # only this one is alive
    my @pairs = hm_ii_drain $m, 100;
    is(scalar @pairs, 2, 'II drain: only non-expired returned');
    is($pairs[1], 6, 'II drain: correct value');
}

# ============================================================
# pop (LRU tail / iter forward) and shift (LRU head / iter backward)
# ============================================================

# LRU pop = take from tail (least recently used)
{
    my $m = Data::HashMap::II->new(100);
    hm_ii_put $m, $_, $_ * 10 for 1..5;
    hm_ii_get $m, 3;  # promote 3 to MRU
    my ($k, $v) = hm_ii_pop $m;
    is($k, 1, 'II LRU pop: key is LRU tail');
    is($v, 10, 'II LRU pop: correct value');
    is(hm_ii_size $m, 4, 'II LRU pop: size decremented');
}

# LRU shift = take from head (most recently used)
{
    my $m = Data::HashMap::II->new(100);
    hm_ii_put $m, $_, $_ * 10 for 1..5;
    hm_ii_get $m, 2;  # promote 2 to MRU
    my ($k, $v) = hm_ii_shift $m;
    is($k, 2, 'II LRU shift: key is MRU head');
    is($v, 20, 'II LRU shift: correct value');
}

# Non-LRU pop (iter forward) exhausts map
{
    my $m = Data::HashMap::II->new();
    hm_ii_put $m, $_, $_ for 1..3;
    my @all;
    while (my @kv = hm_ii_pop $m) { push @all, @kv; }
    is(scalar @all, 6, 'II non-LRU pop: all 3 pairs consumed');
    is(hm_ii_size $m, 0, 'II non-LRU pop: map empty');
}

# Non-LRU shift (iter backward) exhausts map
{
    my $m = Data::HashMap::II->new();
    hm_ii_put $m, $_, $_ for 1..3;
    my @all;
    while (my @kv = hm_ii_shift $m) { push @all, @kv; }
    is(scalar @all, 6, 'II non-LRU shift: all 3 pairs consumed');
    is(hm_ii_size $m, 0, 'II non-LRU shift: map empty');
}

# SS pop
{
    my $m = Data::HashMap::SS->new(10);
    hm_ss_put $m, "a", "1";
    hm_ss_put $m, "b", "2";
    my ($k, $v) = hm_ss_pop $m;
    is($v, "1", 'SS LRU pop: returns LRU tail value');
}

# IA pop with SV* values
{
    my $m = Data::HashMap::IA->new(10);
    hm_ia_put $m, 1, [42];
    hm_ia_put $m, 2, [99];
    my ($k, $v) = hm_ia_pop $m;
    is_deeply($v, [42], 'IA LRU pop: SV* value intact');
    is(hm_ia_size $m, 1, 'IA LRU pop: size decremented');
}

# pop on empty map returns empty list
{
    my $m = Data::HashMap::II->new(10);
    my @r = hm_ii_pop $m;
    is(scalar @r, 0, 'II pop empty: returns empty list');
    @r = hm_ii_shift $m;
    is(scalar @r, 0, 'II shift empty: returns empty list');
}

# ============================================================
# UTF-8 key preservation in drain/pop/shift (regression)
# ============================================================

{
    my $m = Data::HashMap::SS->new();
    hm_ss_put $m, "\x{100}key", "val";
    my @d = hm_ss_drain $m, 1;
    ok(utf8::is_utf8($d[0]), 'SS drain: UTF-8 key flag preserved');
    is($d[0], "\x{100}key", 'SS drain: UTF-8 key correct');
}

{
    my $m = Data::HashMap::SI->new(10);  # LRU
    hm_si_put $m, "\x{100}a", 1;
    my ($k, $v) = hm_si_pop $m;
    ok(utf8::is_utf8($k), 'SI LRU pop: UTF-8 key flag preserved');
    is($k, "\x{100}a", 'SI LRU pop: UTF-8 key correct');
}

{
    my $m = Data::HashMap::SA->new(10);  # LRU
    hm_sa_put $m, "\x{100}b", [42];
    my ($k, $v) = hm_sa_shift $m;
    ok(utf8::is_utf8($k), 'SA LRU shift: UTF-8 key flag preserved');
    is($k, "\x{100}b", 'SA LRU shift: UTF-8 key correct');
    is_deeply($v, [42], 'SA LRU shift: SV* value intact');
}

# string-value drain/pop correctness (validates no corruption from free)
{
    my $m = Data::HashMap::IS->new();
    hm_is_put $m, $_, "val$_" for 1..10;
    my @d = hm_is_drain $m, 5;
    is(scalar @d, 10, 'IS drain: 5 pairs returned');
    is(hm_is_size $m, 5, 'IS drain: 5 remain');

    while (my @kv = hm_is_pop $m) { }
    is(hm_is_size $m, 0, 'IS pop: exhausted remaining');
}

# ============================================================
# pop/shift/drain coverage for remaining variants
# ============================================================

# I32
{
    my $m = Data::HashMap::I32->new();
    hm_i32_put $m, $_, $_ * 10 for 1..5;
    is(hm_i32_take $m, 1, 10, 'I32 take');
    my @d = hm_i32_drain $m, 2;
    is(scalar @d, 4, 'I32 drain: 2 pairs');
    my @p = hm_i32_pop $m;
    is(scalar @p, 2, 'I32 pop: returns pair');
}
{
    my $m = Data::HashMap::I32->new();
    hm_i32_put $m, $_, $_ for 1..3;
    my @s = hm_i32_shift $m;
    is(scalar @s, 2, 'I32 shift: returns pair');
}

# I16
{
    my $m = Data::HashMap::I16->new();
    hm_i16_put $m, $_, $_ for 1..3;
    is(hm_i16_take $m, 1, 1, 'I16 take');
    my @d = hm_i16_drain $m, 1;
    is(scalar @d, 2, 'I16 drain');
    my @p = hm_i16_pop $m;
    is(scalar @p, 2, 'I16 pop');
}

# I32S
{
    my $m = Data::HashMap::I32S->new();
    hm_i32s_put $m, 1, "v1";
    is(hm_i32s_take $m, 1, "v1", 'I32S take');
    hm_i32s_put $m, $_, "v$_" for 1..3;
    my @d = hm_i32s_drain $m, 2;
    is(scalar @d, 4, 'I32S drain');
}

# I16S
{
    my $m = Data::HashMap::I16S->new();
    hm_i16s_put $m, 1, "v1";
    is(hm_i16s_take $m, 1, "v1", 'I16S take');
}

# SI32
{
    my $m = Data::HashMap::SI32->new();
    hm_si32_put $m, "k", 42;
    is(hm_si32_take $m, "k", 42, 'SI32 take');
    hm_si32_put $m, "a", 1;
    hm_si32_put $m, "b", 2;
    my @d = hm_si32_drain $m, 1;
    is(scalar @d, 2, 'SI32 drain');
}

# SI16
{
    my $m = Data::HashMap::SI16->new();
    hm_si16_put $m, "k", 7;
    is(hm_si16_take $m, "k", 7, 'SI16 take');
}

# I32A
{
    my $m = Data::HashMap::I32A->new();
    hm_i32a_put $m, 1, [10];
    my $v = hm_i32a_take $m, 1;
    is_deeply($v, [10], 'I32A take');
}

# I16A
{
    my $m = Data::HashMap::I16A->new();
    hm_i16a_put $m, 1, {x => 1};
    my $v = hm_i16a_take $m, 1;
    is_deeply($v, {x => 1}, 'I16A take');
}

# UTF-8 key regression for SI32 and SI16
{
    my $m = Data::HashMap::SI32->new(10);
    hm_si32_put $m, "\x{100}key", 99;
    my ($k, $v) = hm_si32_pop $m;
    ok(utf8::is_utf8($k), 'SI32 pop: UTF-8 key preserved');
    is($v, 99, 'SI32 pop: value correct');
}

{
    my $m = Data::HashMap::SI16->new(10);
    hm_si16_put $m, "\x{100}key", 7;
    my ($k, $v) = hm_si16_pop $m;
    ok(utf8::is_utf8($k), 'SI16 pop: UTF-8 key preserved');
    is($v, 7, 'SI16 pop: value correct');
}

# ============================================================
# reserve
# ============================================================

{
    my $m = Data::HashMap::II->new();
    hm_ii_reserve $m, 100000;
    hm_ii_put $m, $_, $_ for 1..1000;
    is(hm_ii_size $m, 1000, 'II reserve: insert after reserve works');
}

# ============================================================
# from_hash
# ============================================================

{
    my $m = Data::HashMap::II->new();
    $m->from_hash({1 => 10, 2 => 20, 3 => 30});
    is(hm_ii_size $m, 3, 'II from_hash: size');
    is(hm_ii_get $m, 2, 20, 'II from_hash: correct value');
}

{
    my $m = Data::HashMap::SS->new();
    $m->from_hash({a => "x", "\x{100}b" => "y"});
    is(hm_ss_size $m, 2, 'SS from_hash: size');
    is(hm_ss_get $m, "a", "x", 'SS from_hash: ASCII key');
    is(hm_ss_get $m, "\x{100}b", "y", 'SS from_hash: UTF-8 key');
}

{
    my $m = Data::HashMap::IA->new();
    $m->from_hash({1 => [42], 2 => {x => 1}});
    is(hm_ia_size $m, 2, 'IA from_hash: SV* values');
    is_deeply(hm_ia_get $m, 1, [42], 'IA from_hash: arrayref value');
}

# ============================================================
# clone
# ============================================================

{
    my $m = Data::HashMap::II->new();
    hm_ii_put $m, $_, $_ * 10 for 1..100;
    my $c = $m->clone;
    is(hm_ii_size $c, 100, 'II clone: size matches');
    is(hm_ii_get $c, 50, 500, 'II clone: values match');
    hm_ii_put $c, 101, 1010;
    is(hm_ii_size $m, 100, 'II clone: original unchanged');
    is(hm_ii_size $c, 101, 'II clone: clone modified independently');
}

{
    my $m = Data::HashMap::SS->new();
    hm_ss_put $m, "k$_", "v$_" for 1..10;
    my $c = $m->clone;
    is(hm_ss_size $c, 10, 'SS clone: size');
    is(hm_ss_get $c, "k5", "v5", 'SS clone: value');
    hm_ss_remove $m, "k5";
    is(hm_ss_get $c, "k5", "v5", 'SS clone: independent after remove');
}

{
    my $m = Data::HashMap::IA->new();
    hm_ia_put $m, 1, [1,2,3];
    my $c = $m->clone;
    is_deeply(hm_ia_get $c, 1, [1,2,3], 'IA clone: SV* value deep-independent');
}

# clone with LRU
{
    my $m = Data::HashMap::II->new(50);
    hm_ii_put $m, $_, $_ for 1..50;
    my $c = $m->clone;
    is(hm_ii_size $c, 50, 'II clone LRU: size');
    is(hm_ii_max_size $c, 50, 'II clone LRU: max_size preserved');
}

# ============================================================
# merge
# ============================================================

{
    my $a = Data::HashMap::II->new();
    my $b = Data::HashMap::II->new();
    hm_ii_put $a, 1, 10;
    hm_ii_put $b, 2, 20;
    hm_ii_put $b, 3, 30;
    $a->merge($b);
    is(hm_ii_size $a, 3, 'II merge: combined size');
    is(hm_ii_get $a, 2, 20, 'II merge: value from source');
    is(hm_ii_size $b, 2, 'II merge: source unchanged');
}

{
    my $a = Data::HashMap::SS->new();
    my $b = Data::HashMap::SS->new();
    hm_ss_put $a, "a", "1";
    hm_ss_put $b, "b", "2";
    $a->merge($b);
    is(hm_ss_size $a, 2, 'SS merge: combined');
    is(hm_ss_get $a, "b", "2", 'SS merge: value from source');
}

# merge overwrites existing keys
{
    my $a = Data::HashMap::II->new();
    my $b = Data::HashMap::II->new();
    hm_ii_put $a, 1, 10;
    hm_ii_put $b, 1, 99;
    $a->merge($b);
    is(hm_ii_get $a, 1, 99, 'II merge: overwrites existing key');
}

# ============================================================
# purge
# ============================================================

{
    my $m = Data::HashMap::II->new(0, 1);
    hm_ii_put $m, $_, $_ for 1..10;
    sleep 2;
    hm_ii_put $m, 11, 11;  # this one is fresh
    hm_ii_purge $m;
    is(hm_ii_size $m, 1, 'II purge: only fresh entry remains');
    is(hm_ii_get $m, 11, 11, 'II purge: fresh entry intact');
}

{
    my $m = Data::HashMap::SS->new(0, 1);
    hm_ss_put $m, "k$_", "v$_" for 1..5;
    sleep 2;
    hm_ss_purge $m;
    is(hm_ss_size $m, 0, 'SS purge: all expired');
}

# ============================================================
# capacity
# ============================================================

{
    my $m = Data::HashMap::II->new();
    is(hm_ii_capacity $m, 16, 'II capacity: initial');
    hm_ii_put $m, $_, $_ for 1..20;
    cmp_ok(hm_ii_capacity $m, '>=', 32, 'II capacity: grew after insert');
}

# ============================================================
# persist
# ============================================================

{
    my $m = Data::HashMap::II->new(0, 1);
    hm_ii_put $m, 1, 42;
    ok(hm_ii_persist $m, 1, 'II persist: returns true');
    sleep 2;
    is(hm_ii_get $m, 1, 42, 'II persist: entry survives past original TTL');
}

{
    my $m = Data::HashMap::SS->new(0, 1);
    hm_ss_put $m, "k", "v";
    ok(hm_ss_persist $m, "k", 'SS persist: returns true');
    sleep 2;
    is(hm_ss_get $m, "k", "v", 'SS persist: entry survives');
}

# ============================================================
# swap
# ============================================================

{
    my $m = Data::HashMap::II->new();
    hm_ii_put $m, 1, 10;
    my $old = $m->swap(1, 99);
    is($old, 10, 'II swap: returns old value');
    is(hm_ii_get $m, 1, 99, 'II swap: new value stored');
    my $miss = $m->swap(999, 0);
    ok(!defined $miss, 'II swap: missing key returns undef');
}

{
    my $m = Data::HashMap::SS->new();
    hm_ss_put $m, "k", "old";
    my $old = $m->swap("k", "new");
    is($old, "old", 'SS swap: returns old string');
    is(hm_ss_get $m, "k", "new", 'SS swap: new string stored');
}

{
    my $m = Data::HashMap::IA->new();
    hm_ia_put $m, 1, [1,2];
    my $old = $m->swap(1, [3,4]);
    is_deeply($old, [1,2], 'IA swap: returns old SV*');
    is_deeply(hm_ia_get $m, 1, [3,4], 'IA swap: new SV* stored');
}

# ============================================================
# cas (int-value variants only)
# ============================================================

{
    my $m = Data::HashMap::II->new();
    hm_ii_put $m, 1, 10;
    ok($m->cas(1, 10, 20), 'II cas: succeeds when expected matches');
    is(hm_ii_get $m, 1, 20, 'II cas: new value stored');
    ok(!$m->cas(1, 10, 30), 'II cas: fails when expected mismatches');
    is(hm_ii_get $m, 1, 20, 'II cas: value unchanged on failure');
    ok(!$m->cas(999, 0, 1), 'II cas: fails for missing key');
}

{
    my $m = Data::HashMap::SI->new();
    hm_si_put $m, "k", 10;
    ok($m->cas("k", 10, 42), 'SI cas: succeeds');
    is(hm_si_get $m, "k", 42, 'SI cas: value updated');
}

# ============================================================
# freeze / thaw
# ============================================================

{
    my $m = Data::HashMap::II->new();
    hm_ii_put $m, $_, $_ * 10 for 1..100;
    my $frozen = $m->freeze;
    ok(length($frozen) > 22, 'II freeze: produces data');
    my $m2 = Data::HashMap::II->thaw($frozen);
    is(hm_ii_size $m2, 100, 'II thaw: correct size');
    is(hm_ii_get $m2, 50, 500, 'II thaw: correct value');
}

{
    my $m = Data::HashMap::SS->new();
    hm_ss_put $m, "hello", "world";
    hm_ss_put $m, "\x{100}key", "\x{200}val";
    my $frozen = $m->freeze;
    my $m2 = Data::HashMap::SS->thaw($frozen);
    is(hm_ss_size $m2, 2, 'SS thaw: size');
    is(hm_ss_get $m2, "hello", "world", 'SS thaw: ASCII');
    my $v = hm_ss_get $m2, "\x{100}key";
    is($v, "\x{200}val", 'SS thaw: UTF-8 value');
    ok(utf8::is_utf8($v), 'SS thaw: UTF-8 flag preserved');
}

{
    my $m = Data::HashMap::I32->new();
    hm_i32_put $m, $_, $_ for 1..10;
    my $f = $m->freeze;
    my $m2 = Data::HashMap::I32->thaw($f);
    is(hm_i32_size $m2, 10, 'I32 freeze/thaw roundtrip');
}

# freeze with LRU preserves max_size
{
    my $m = Data::HashMap::II->new(50);
    hm_ii_put $m, $_, $_ for 1..50;
    my $f = $m->freeze;
    my $m2 = Data::HashMap::II->thaw($f);
    is(hm_ii_max_size $m2, 50, 'II thaw: max_size preserved');
}

# SV* freeze croaks
{
    my $m = Data::HashMap::IA->new();
    hm_ia_put $m, 1, [42];
    eval { $m->freeze };
    like($@, qr/not supported/, 'IA freeze: croaks for SV*');
}

# persist on expired key returns false
{
    my $m = Data::HashMap::II->new(0, 1);
    hm_ii_put $m, 1, 42;
    sleep 2;
    my $ok = $m->persist(1);
    ok(!$ok, 'II persist: expired key returns false');
}

# freeze/thaw with stale TTL entries
{
    my $m = Data::HashMap::II->new(0, 1);
    hm_ii_put $m, $_, $_ for 1..10;
    sleep 2;
    hm_ii_put $m, 11, 11;  # only this one is live
    my $frozen = $m->freeze;
    my $m2 = Data::HashMap::II->thaw($frozen);
    is(hm_ii_size $m2, 1, 'II freeze/thaw: stale TTL entries excluded');
    is(hm_ii_get $m2, 11, 11, 'II freeze/thaw: live entry preserved');
}

# freeze/thaw preserves persist (no-TTL) entries on TTL maps
{
    my $m = Data::HashMap::II->new(0, 2);
    hm_ii_put $m, 1, 100;
    hm_ii_persist $m, 1;
    hm_ii_put $m, 2, 200;
    my $frozen = $m->freeze;
    my $m2 = Data::HashMap::II->thaw($frozen);
    sleep 3;
    is(hm_ii_get $m2, 1, 100, 'II freeze/thaw: persisted entry survives past TTL');
    is(hm_ii_get $m2, 2, undef, 'II freeze/thaw: TTL entry expires normally');
}

{
    my $m = Data::HashMap::SS->new(0, 2);
    hm_ss_put $m, "k", "v";
    hm_ss_persist $m, "k";
    hm_ss_put $m, "k2", "v2";
    my $frozen = $m->freeze;
    my $m2 = Data::HashMap::SS->thaw($frozen);
    sleep 3;
    is(hm_ss_get $m2, "k", "v", 'SS freeze/thaw: persisted entry survives past TTL');
    is(hm_ss_get $m2, "k2", undef, 'SS freeze/thaw: TTL entry expires normally');
}

# thaw truncated data croaks
{
    eval { Data::HashMap::II->thaw("DHMP" . "\x01\x01" . "\0" x 10) };
    like($@, qr/Truncated|Invalid/, 'II thaw: short header croaks');
}

# thaw mid-loop truncation (cnt=5 but only 1 entry)
{
    my $hdr = "DHMP" . "\x01\x01"
             . pack("V", 5)        # cnt = 5
             . pack("V", 0) . pack("V", 0) . pack("V", 0);
    my $one = pack("q", 1) . pack("q", 10) . pack("V", 0);  # 1 II entry (native endian)
    eval { Data::HashMap::II->thaw($hdr . $one) };
    like($@, qr/Truncated/, 'II thaw: mid-loop truncation croaks');
}

# thaw rejects cross-variant data
{
    my $m = Data::HashMap::SS->new();
    hm_ss_put $m, "a", "b";
    my $ss_frozen = $m->freeze;
    eval { Data::HashMap::II->thaw($ss_frozen) };
    like($@, qr/Variant mismatch/, 'II thaw rejects SS freeze data');
}

# ============================================================
# from_hash round-trip
# ============================================================

{
    my $m = Data::HashMap::II->new();
    hm_ii_put $m, $_, $_ * 10 for 1..50;
    my $h = hm_ii_to_hash $m;
    my $m2 = Data::HashMap::II->new();
    $m2->from_hash($h);
    is(hm_ii_size $m2, 50, 'II from_hash round-trip: size');
    is(hm_ii_get $m2, 25, 250, 'II from_hash round-trip: value');
}

{
    my $m = Data::HashMap::SI->new();
    hm_si_put $m, "k$_", $_ for 1..20;
    my $h = hm_si_to_hash $m;
    my $m2 = Data::HashMap::SI->new();
    $m2->from_hash($h);
    is(hm_si_size $m2, 20, 'SI from_hash round-trip: size');
    is(hm_si_get $m2, "k10", 10, 'SI from_hash round-trip: value');
}

# ============================================================
# merge overwrites + LRU eviction
# ============================================================

{
    my $m1 = Data::HashMap::II->new();
    hm_ii_put $m1, 1, 10;
    hm_ii_put $m1, 2, 20;
    my $m2 = Data::HashMap::II->new();
    hm_ii_put $m2, 2, 99;
    hm_ii_put $m2, 3, 30;
    $m1->merge($m2);
    is(hm_ii_size $m1, 3, 'II merge: combined size');
    is(hm_ii_get $m1, 2, 99, 'II merge: overwrites existing key');
    is(hm_ii_get $m1, 3, 30, 'II merge: adds new key');
}

{
    my $m1 = Data::HashMap::II->new(3);  # LRU cap=3
    hm_ii_put $m1, 1, 10;
    hm_ii_put $m1, 2, 20;
    hm_ii_put $m1, 3, 30;
    my $m2 = Data::HashMap::II->new();
    hm_ii_put $m2, 4, 40;
    hm_ii_put $m2, 5, 50;
    $m1->merge($m2);
    is(hm_ii_size $m1, 3, 'II merge into LRU: stays at capacity');
    ok(defined(hm_ii_get $m1, 5), 'II merge into LRU: newest survives');
}

# ============================================================
# clone preserves LRU order and TTL
# ============================================================

{
    my $m = Data::HashMap::II->new(5);
    hm_ii_put $m, $_, $_ * 10 for 1..5;
    hm_ii_get $m, 1;  # promote key 1 to head
    my $c = $m->clone;
    is(hm_ii_size $c, 5, 'II clone LRU: size');
    # Insert one more to evict LRU tail — should be key 2, not key 1
    hm_ii_put $c, 6, 60;
    ok(defined(hm_ii_get $c, 1), 'II clone LRU: promoted key survives eviction');
    ok(!defined(hm_ii_get $c, 2), 'II clone LRU: LRU tail evicted');
}

{
    my $m = Data::HashMap::II->new(0, 1);
    hm_ii_put $m, 1, 42;
    my $c = $m->clone;
    sleep 2;
    is(hm_ii_get $c, 1, undef, 'II clone TTL: entry expires in clone');
}

# ============================================================
# swap missing key for string-key and SV* variants
# ============================================================

{
    my $m = Data::HashMap::SS->new();
    my $v = $m->swap("missing", "val");
    ok(!defined $v, 'SS swap missing key: returns undef');
    is(hm_ss_size $m, 0, 'SS swap missing key: no insertion');
}

{
    my $m = Data::HashMap::IA->new();
    my $v = $m->swap(999, [1]);
    ok(!defined $v, 'IA swap missing key: returns undef');
    is(hm_ia_size $m, 0, 'IA swap missing key: no insertion');
}

# ============================================================
# pop/shift on LRU+TTL skips expired entries
# ============================================================

{
    my $m = Data::HashMap::II->new(10, 1);  # LRU + TTL=1s
    hm_ii_put $m, 1, 10;
    hm_ii_put $m, 2, 20;
    sleep 2;
    hm_ii_put $m, 3, 30;  # only this one is live
    my ($k, $v) = hm_ii_pop $m;
    is($k, 3, 'II LRU+TTL pop: skips expired, returns live entry');
    is($v, 30, 'II LRU+TTL pop: correct value');
}

{
    my $m = Data::HashMap::II->new(10, 1);
    hm_ii_put $m, 1, 10;
    sleep 2;
    hm_ii_put $m, 2, 20;  # head (MRU)
    my ($k, $v) = hm_ii_shift $m;
    is($k, 2, 'II LRU+TTL shift: skips expired, returns live head');
}

# ============================================================
# drain on LRU map
# ============================================================

{
    my $m = Data::HashMap::II->new(10);
    hm_ii_put $m, $_, $_ * 10 for 1..10;
    my @d = hm_ii_drain $m, 3;
    is(scalar @d, 6, 'II LRU drain: 3 pairs returned');
    is(hm_ii_size $m, 7, 'II LRU drain: 7 remain');
}

# ============================================================
# freeze/thaw preserves lru_skip
# ============================================================

{
    my $m = Data::HashMap::II->new(100, 0, 90);
    hm_ii_put $m, 1, 42;
    my $f = $m->freeze;
    my $m2 = Data::HashMap::II->thaw($f);
    is(hm_ii_lru_skip $m2, 90, 'II freeze/thaw: lru_skip preserved');
    is(hm_ii_max_size $m2, 100, 'II freeze/thaw: max_size preserved');
}

done_testing;
