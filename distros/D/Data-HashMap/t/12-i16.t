use strict;
use warnings;
use Test::More;

use Data::HashMap::I16;

my $map = Data::HashMap::I16->new();
ok(defined $map, 'new()');
isa_ok($map, 'Data::HashMap::I16');

# put and get (keyword API)
ok(hm_i16_put $map, 42, 100, 'put');
is(hm_i16_get $map, 42, 100, 'get');

# method dispatch API
ok($map->put(43, 200), 'method put');
is($map->get(43), 200, 'method get');
ok($map->exists(43), 'method exists');
ok($map->remove(43), 'method remove');
is($map->get(43), undef, 'method get after remove');
is($map->size(), 1, 'method size');

# exists
ok(hm_i16_exists $map, 42, 'exists true');
{
    my $e = hm_i16_exists $map, 99;
    ok(!$e, 'exists false');
}

# undef for missing
is(hm_i16_get $map, 99, undef, 'get missing');

# overwrite
ok(hm_i16_put $map, 42, 200, 'overwrite');
is(hm_i16_get $map, 42, 200, 'get overwritten');

# remove
ok(hm_i16_remove $map, 42, 'remove');
is(hm_i16_get $map, 42, undef, 'get after remove');
{
    my $r = hm_i16_remove $map, 42;
    ok(!$r, 'remove non-existent');
}

# incr
is(hm_i16_incr $map, 10, 1, 'incr new key');
is(hm_i16_incr $map, 10, 2, 'incr again');

# decr
is(hm_i16_decr $map, 20, -1, 'decr new key');
is(hm_i16_decr $map, 20, -2, 'decr again');

# incr_by
is(hm_i16_incr_by $map, 30, 10, 10, 'incr_by 10');
is(hm_i16_incr_by $map, 30, 5, 15, 'incr_by 5');
is(hm_i16_incr_by $map, 30, -3, 12, 'incr_by -3');

# method counter API
$map->put(77, 0);
is($map->incr(77), 1, 'method incr');
is($map->decr(77), 0, 'method decr');
is($map->incr_by(77, 5), 5, 'method incr_by');

# negative key/value
ok(hm_i16_put $map, -100, -200, 'negative');
is(hm_i16_get $map, -100, -200, 'get negative');

# size
is(hm_i16_size $map, 5, 'size');

# keys, values, items
$map = Data::HashMap::I16->new();
hm_i16_put $map, 1, 10;
hm_i16_put $map, 2, 20;
my @keys = sort { $a <=> $b } (hm_i16_keys $map);
is_deeply(\@keys, [1, 2], 'keys');

my @vals = sort { $a <=> $b } (hm_i16_values $map);
is_deeply(\@vals, [10, 20], 'values');

my @items = hm_i16_items $map;
my %h = @items;
is($h{1}, 10, 'items k1');
is($h{2}, 20, 'items k2');

# method iteration
my @mkeys = sort { $a <=> $b } $map->keys();
is_deeply(\@mkeys, [1, 2], 'method keys');
my @mvals = sort { $a <=> $b } $map->values();
is_deeply(\@mvals, [10, 20], 'method values');

# sentinel key rejection (INT16_MIN=-32768 and INT16_MIN+1=-32767 are reserved)
my $i16_min = -32768;
{
    my $r = hm_i16_put $map, $i16_min, 1;
    ok(!$r, 'INT16_MIN key rejected by put');
}
is(hm_i16_get $map, $i16_min, undef, 'INT16_MIN key rejected by get');
{
    my $e = hm_i16_exists $map, $i16_min;
    ok(!$e, 'INT16_MIN key rejected by exists');
}
{
    my $r = hm_i16_put $map, $i16_min + 1, 1;
    ok(!$r, 'INT16_MIN+1 key rejected by put');
}

# overflow protection
$map = Data::HashMap::I16->new();
hm_i16_put $map, 1, 32766;  # INT16_MAX - 1
is(hm_i16_incr $map, 1, 32767, 'incr to INT16_MAX');
eval { hm_i16_incr $map, 1 };
like($@, qr/increment failed/, 'incr at INT16_MAX croaks');

hm_i16_put $map, 2, -32767;  # INT16_MIN + 1
is(hm_i16_decr $map, 2, -32768, 'decr to INT16_MIN');
eval { hm_i16_decr $map, 2 };
like($@, qr/decrement failed/, 'decr at INT16_MIN croaks');

hm_i16_put $map, 3, 32760;
eval { hm_i16_incr_by $map, 3, 100 };
like($@, qr/incr_by failed/, 'incr_by overflow croaks');

hm_i16_put $map, 4, -32760;
eval { hm_i16_incr_by $map, 4, -100 };
like($@, qr/incr_by failed/, 'incr_by underflow croaks');

# sentinel key rejection for remove, incr, decr
{
    my $r = hm_i16_remove $map, $i16_min;
    ok(!$r, 'INT16_MIN key rejected by remove');
}
eval { hm_i16_incr $map, $i16_min };
like($@, qr/increment failed/, 'INT16_MIN key rejected by incr');
eval { hm_i16_decr $map, $i16_min };
like($@, qr/decrement failed/, 'INT16_MIN key rejected by decr');

# incr_by with delta=0
$map = Data::HashMap::I16->new();
is(hm_i16_incr_by $map, 50, 0, 0, 'incr_by 0 on new key');
hm_i16_put $map, 51, 42;
is(hm_i16_incr_by $map, 51, 0, 42, 'incr_by 0 on existing key');

# empty map iteration
$map = Data::HashMap::I16->new();
is_deeply([hm_i16_keys $map], [], 'keys on empty map');

# stress: many entries within int16 range
$map = Data::HashMap::I16->new();
for my $i (1..1000) {
    hm_i16_put $map, $i, $i * 2;
}
is(hm_i16_size $map, 1000, 'stress: 1000 entries');
is(hm_i16_get $map, 500, 1000, 'stress: get middle key');

done_testing;
