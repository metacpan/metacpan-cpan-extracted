use strict;
use warnings;
use Test::More;

use Data::HashMap::SI16;

my $map = Data::HashMap::SI16->new();
ok(defined $map, 'new()');
isa_ok($map, 'Data::HashMap::SI16');

# put and get (keyword)
ok(hm_si16_put $map, "hello", 42, 'put');
is(hm_si16_get $map, "hello", 42, 'get');

# method dispatch
ok($map->put("world", 99), 'method put');
is($map->get("world"), 99, 'method get');
ok($map->exists("world"), 'method exists');
is($map->size(), 2, 'method size');

# overwrite
ok(hm_si16_put $map, "hello", 100, 'overwrite');
is(hm_si16_get $map, "hello", 100, 'get overwritten');

# exists
ok(hm_si16_exists $map, "hello", 'exists true');
{
    my $e = hm_si16_exists $map, "missing";
    ok(!$e, 'exists false');
}

# remove
ok(hm_si16_remove $map, "hello", 'remove');
is(hm_si16_get $map, "hello", undef, 'get after remove');
{
    my $r = hm_si16_remove $map, "hello";
    ok(!$r, 'remove non-existent');
}

# counter operations
is(hm_si16_incr $map, "cnt", 1, 'incr new key');
is(hm_si16_incr $map, "cnt", 2, 'incr again');
is(hm_si16_decr $map, "cnt", 1, 'decr');
is(hm_si16_decr $map, "newdecr", -1, 'decr new key');
is(hm_si16_incr_by $map, "cnt", 10, 11, 'incr_by 10');
is(hm_si16_incr_by $map, "cnt", -5, 6, 'incr_by -5');
is(hm_si16_incr_by $map, "negby", -5, -5, 'incr_by negative on new key');

# method counter API
is($map->incr("mcnt"), 1, 'method incr');
is($map->decr("mcnt"), 0, 'method decr');
is($map->incr_by("mcnt", 7), 7, 'method incr_by');

# overflow protection
$map = Data::HashMap::SI16->new();
hm_si16_put $map, "max", 32766;
is(hm_si16_incr $map, "max", 32767, 'incr to INT16_MAX');
eval { hm_si16_incr $map, "max" };
like($@, qr/increment failed/, 'incr at INT16_MAX croaks');

hm_si16_put $map, "min", -32767;
is(hm_si16_decr $map, "min", -32768, 'decr to INT16_MIN');
eval { hm_si16_decr $map, "min" };
like($@, qr/decrement failed/, 'decr at INT16_MIN croaks');

hm_si16_put $map, "oflow", 32760;
eval { hm_si16_incr_by $map, "oflow", 10 };
like($@, qr/incr_by failed/, 'incr_by overflow croaks');
hm_si16_put $map, "uflow", -32760;
my $neg = -10;
eval { hm_si16_incr_by $map, "uflow", $neg };
like($@, qr/incr_by failed/, 'incr_by underflow croaks');

# size
$map = Data::HashMap::SI16->new();
hm_si16_put $map, "a", 1;
hm_si16_put $map, "b", 2;
is(hm_si16_size $map, 2, 'size');

# keys, values, items
my @keys = sort (hm_si16_keys $map);
is_deeply(\@keys, ["a", "b"], 'keys');

my @vals = sort { $a <=> $b } (hm_si16_values $map);
is_deeply(\@vals, [1, 2], 'values');

my @items = hm_si16_items $map;
my %h = @items;
is($h{"a"}, 1, 'items k1');
is($h{"b"}, 2, 'items k2');

# UTF-8 keys
my $utf8_key = "\x{263A}";
ok(hm_si16_put $map, $utf8_key, 77, 'put utf8 key');
is(hm_si16_get $map, $utf8_key, 77, 'get utf8 key');
ok(hm_si16_exists $map, $utf8_key, 'exists utf8 key');

# empty map
$map = Data::HashMap::SI16->new();
is_deeply([hm_si16_keys $map], [], 'keys on empty map');
is(hm_si16_size $map, 0, 'size of empty map');

done_testing;
