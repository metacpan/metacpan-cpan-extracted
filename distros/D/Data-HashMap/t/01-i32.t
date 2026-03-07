use strict;
use warnings;
use Test::More;

use Data::HashMap::I32;

my $map = Data::HashMap::I32->new();
ok(defined $map, 'new()');
isa_ok($map, 'Data::HashMap::I32');

# put and get
ok(hm_i32_put $map, 42, 100, 'put');
is(hm_i32_get $map, 42, 100, 'get');

# exists
ok(hm_i32_exists $map, 42, 'exists true');
{
    my $e = hm_i32_exists $map, 99;
    ok(!$e, 'exists false');
}

# undef for missing
is(hm_i32_get $map, 99, undef, 'get missing');

# overwrite
ok(hm_i32_put $map, 42, 200, 'overwrite');
is(hm_i32_get $map, 42, 200, 'get overwritten');

# remove
ok(hm_i32_remove $map, 42, 'remove');
is(hm_i32_get $map, 42, undef, 'get after remove');
{
    my $r = hm_i32_remove $map, 42;
    ok(!$r, 'remove non-existent');
}

# incr
is(hm_i32_incr $map, 10, 1, 'incr new key');
is(hm_i32_incr $map, 10, 2, 'incr again');

# decr
is(hm_i32_decr $map, 20, -1, 'decr new key');
is(hm_i32_decr $map, 20, -2, 'decr again');

# incr_by
is(hm_i32_incr_by $map, 30, 10, 10, 'incr_by 10');
is(hm_i32_incr_by $map, 30, 5, 15, 'incr_by 5');
is(hm_i32_incr_by $map, 30, -3, 12, 'incr_by -3');

# negative key/value
ok(hm_i32_put $map, -100, -200, 'negative');
is(hm_i32_get $map, -100, -200, 'get negative');

# size
is(hm_i32_size $map, 4, 'size');

# keys, values, items
$map = Data::HashMap::I32->new();
hm_i32_put $map, 1, 10;
hm_i32_put $map, 2, 20;
my @keys = sort { $a <=> $b } hm_i32_keys $map;
is_deeply(\@keys, [1, 2], 'keys');

my @vals = sort { $a <=> $b } hm_i32_values $map;
is_deeply(\@vals, [10, 20], 'values');

my @items = hm_i32_items $map;
my %h = @items;
is($h{1}, 10, 'items k1');
is($h{2}, 20, 'items k2');

# sentinel key rejection (INT32_MIN and INT32_MIN+1 are reserved)
my $i32_min = -2147483648;
{
    my $r = hm_i32_put $map, $i32_min, 1;
    ok(!$r, 'INT32_MIN key rejected by put');
}
is(hm_i32_get $map, $i32_min, undef, 'INT32_MIN key rejected by get');
{
    my $e = hm_i32_exists $map, $i32_min;
    ok(!$e, 'INT32_MIN key rejected by exists');
}
{
    my $r = hm_i32_put $map, $i32_min + 1, 1;
    ok(!$r, 'INT32_MIN+1 key rejected by put');
}

# overflow protection
$map = Data::HashMap::I32->new();
hm_i32_put $map, 1, 2147483646;  # INT32_MAX - 1
is(hm_i32_incr $map, 1, 2147483647, 'incr to INT32_MAX');
eval { hm_i32_incr $map, 1 };
like($@, qr/increment failed/, 'incr at INT32_MAX croaks');

hm_i32_put $map, 2, -2147483647;  # INT32_MIN + 1
is(hm_i32_decr $map, 2, -2147483648, 'decr to INT32_MIN');
eval { hm_i32_decr $map, 2 };
like($@, qr/decrement failed/, 'decr at INT32_MIN croaks');

hm_i32_put $map, 3, 2147483640;
eval { hm_i32_incr_by $map, 3, 100 };
like($@, qr/incr_by failed/, 'incr_by overflow croaks');

hm_i32_put $map, 4, -2147483640;
eval { hm_i32_incr_by $map, 4, -100 };
like($@, qr/incr_by failed/, 'incr_by underflow croaks');

# sentinel key rejection for remove, incr, decr
{
    my $r = hm_i32_remove $map, $i32_min;
    ok(!$r, 'INT32_MIN key rejected by remove');
}
eval { hm_i32_incr $map, $i32_min };
like($@, qr/increment failed/, 'INT32_MIN key rejected by incr');
eval { hm_i32_decr $map, $i32_min };
like($@, qr/decrement failed/, 'INT32_MIN key rejected by decr');

# incr_by with delta=0
$map = Data::HashMap::I32->new();
is(hm_i32_incr_by $map, 50, 0, 0, 'incr_by 0 on new key');
hm_i32_put $map, 51, 42;
is(hm_i32_incr_by $map, 51, 0, 42, 'incr_by 0 on existing key');

# put then incr on same key
$map = Data::HashMap::I32->new();
hm_i32_put $map, 60, 5;
is(hm_i32_incr $map, 60, 6, 'incr after put');

# empty map iteration
$map = Data::HashMap::I32->new();
is_deeply([hm_i32_keys $map], [], 'keys on empty map');

done_testing;
