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

done_testing;
