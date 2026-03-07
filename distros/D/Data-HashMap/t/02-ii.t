use strict;
use warnings;
use Test::More;

use Data::HashMap::II;

my $map = Data::HashMap::II->new();
ok(defined $map, 'new()');
isa_ok($map, 'Data::HashMap::II');

# put and get
ok(hm_ii_put $map, 42, 100, 'put');
is(hm_ii_get $map, 42, 100, 'get');

# exists
ok(hm_ii_exists $map, 42, 'exists true');
{
    my $e = hm_ii_exists $map, 99;
    ok(!$e, 'exists false');
}

# undef for missing
is(hm_ii_get $map, 99, undef, 'get missing');

# overwrite
ok(hm_ii_put $map, 42, 200, 'overwrite');
is(hm_ii_get $map, 42, 200, 'get overwritten');

# remove
ok(hm_ii_remove $map, 42, 'remove');
is(hm_ii_get $map, 42, undef, 'get after remove');
{
    my $r = hm_ii_remove $map, 42;
    ok(!$r, 'remove non-existent');
}

# incr
is(hm_ii_incr $map, 10, 1, 'incr new key');
is(hm_ii_incr $map, 10, 2, 'incr again');
is(hm_ii_incr $map, 10, 3, 'incr third');

# decr
is(hm_ii_decr $map, 20, -1, 'decr new key');
is(hm_ii_decr $map, 20, -2, 'decr again');

# incr_by
is(hm_ii_incr_by $map, 30, 10, 10, 'incr_by 10');
is(hm_ii_incr_by $map, 30, 5, 15, 'incr_by 5');
is(hm_ii_incr_by $map, 30, -3, 12, 'incr_by -3');

# large values
ok(hm_ii_put $map, 1, 9_000_000_000_000_000_000, 'put large');
is(hm_ii_get $map, 1, 9_000_000_000_000_000_000, 'get large');

# negative
ok(hm_ii_put $map, -100, -200, 'negative');
is(hm_ii_get $map, -100, -200, 'get negative');

# size, keys, values, items
$map = Data::HashMap::II->new();
hm_ii_put $map, 1, 10;
hm_ii_put $map, 2, 20;
is(hm_ii_size $map, 2, 'size');

my @keys = sort { $a <=> $b } hm_ii_keys $map;
is_deeply(\@keys, [1, 2], 'keys');

my @vals = sort { $a <=> $b } hm_ii_values $map;
is_deeply(\@vals, [10, 20], 'values');

my @items = hm_ii_items $map;
my %h = @items;
is_deeply(\%h, {1 => 10, 2 => 20}, 'items');

# sentinel key rejection (INT64_MIN and INT64_MIN+1 are reserved)
my $i64_min = -9223372036854775808;
{
    my $r = hm_ii_put $map, $i64_min, 1;
    ok(!$r, 'INT64_MIN key rejected by put');
}
is(hm_ii_get $map, $i64_min, undef, 'INT64_MIN key rejected by get');
{
    my $e = hm_ii_exists $map, $i64_min;
    ok(!$e, 'INT64_MIN key rejected by exists');
}
{
    my $r = hm_ii_put $map, $i64_min + 1, 1;
    ok(!$r, 'INT64_MIN+1 key rejected by put');
}

# overflow protection
$map = Data::HashMap::II->new();
hm_ii_put $map, 1, 9223372036854775806;  # INT64_MAX - 1
is(hm_ii_incr $map, 1, 9223372036854775807, 'incr to INT64_MAX');
eval { hm_ii_incr $map, 1 };
like($@, qr/increment failed/, 'incr at INT64_MAX croaks');

hm_ii_put $map, 2, -9223372036854775807;  # INT64_MIN + 1
is(hm_ii_decr $map, 2, -9223372036854775808, 'decr to INT64_MIN');
eval { hm_ii_decr $map, 2 };
like($@, qr/decrement failed/, 'decr at INT64_MIN croaks');

hm_ii_put $map, 3, 9223372036854775800;
eval { hm_ii_incr_by $map, 3, 100 };
like($@, qr/incr_by failed/, 'incr_by overflow croaks');

hm_ii_put $map, 4, -9223372036854775800;
eval { hm_ii_incr_by $map, 4, -100 };
like($@, qr/incr_by failed/, 'incr_by underflow croaks');

# sentinel key rejection for remove, incr, decr
{
    my $r = hm_ii_remove $map, $i64_min;
    ok(!$r, 'INT64_MIN key rejected by remove');
}
eval { hm_ii_incr $map, $i64_min };
like($@, qr/increment failed/, 'INT64_MIN key rejected by incr');
eval { hm_ii_decr $map, $i64_min };
like($@, qr/decrement failed/, 'INT64_MIN key rejected by decr');

# incr_by with delta=0
$map = Data::HashMap::II->new();
is(hm_ii_incr_by $map, 50, 0, 0, 'incr_by 0 on new key');
hm_ii_put $map, 51, 42;
is(hm_ii_incr_by $map, 51, 0, 42, 'incr_by 0 on existing key');

# put then incr on same key
$map = Data::HashMap::II->new();
hm_ii_put $map, 60, 5;
is(hm_ii_incr $map, 60, 6, 'incr after put');

# empty map iteration
$map = Data::HashMap::II->new();
is_deeply([hm_ii_keys $map], [], 'keys on empty map');

done_testing;
