use strict;
use warnings;
use Test::More;

use Data::HashMap::I32S;

my $map = Data::HashMap::I32S->new();
ok(defined $map, 'new()');
isa_ok($map, 'Data::HashMap::I32S');

# put and get
ok(hm_i32s_put $map, 1, "hello", 'put');
is(hm_i32s_get $map, 1, "hello", 'get');

ok(hm_i32s_put $map, 2, "world", 'put 2');
is(hm_i32s_get $map, 2, "world", 'get 2');

# overwrite
ok(hm_i32s_put $map, 1, "replaced", 'overwrite');
is(hm_i32s_get $map, 1, "replaced", 'get overwritten');

# empty string
ok(hm_i32s_put $map, 3, "", 'put empty string');
is(hm_i32s_get $map, 3, "", 'get empty string');

# exists and remove
ok(hm_i32s_exists $map, 1, 'exists true');
{
    my $e = hm_i32s_exists $map, 99;
    ok(!$e, 'exists false');
}
ok(hm_i32s_remove $map, 1, 'remove');
is(hm_i32s_get $map, 1, undef, 'get after remove');
{
    my $r = hm_i32s_remove $map, 1;
    ok(!$r, 'remove non-existent');
}

# UTF-8
{
    my $utf8 = "\x{263A}\x{2603}";
    ok(hm_i32s_put $map, 10, $utf8, 'put UTF-8');
    my $got = hm_i32s_get $map, 10;
    is($got, $utf8, 'get UTF-8');
    ok(utf8::is_utf8($got), 'UTF-8 flag preserved');
}

# size — keys 2, 3, 10 (key 1 was removed)
is(hm_i32s_size $map, 3, 'size');

# keys, values, items
$map = Data::HashMap::I32S->new();
hm_i32s_put $map, 1, "a";
hm_i32s_put $map, 2, "b";
my @keys = sort { $a <=> $b } hm_i32s_keys $map;
is_deeply(\@keys, [1, 2], 'keys');

my @vals = sort { $a cmp $b } (hm_i32s_values $map);
is_deeply(\@vals, ["a", "b"], 'values');

my @items = hm_i32s_items $map;
my %h = @items;
is($h{1}, "a", 'items k1');
is($h{2}, "b", 'items k2');

# sentinel key rejection (INT32_MIN and INT32_MIN+1 are reserved)
my $i32_min = -2147483648;
{
    my $r = hm_i32s_put $map, $i32_min, "x";
    ok(!$r, 'INT32_MIN key rejected by put');
}
is(hm_i32s_get $map, $i32_min, undef, 'INT32_MIN key rejected by get');
{
    my $e = hm_i32s_exists $map, $i32_min;
    ok(!$e, 'INT32_MIN key rejected by exists');
}
{
    my $r = hm_i32s_put $map, $i32_min + 1, "x";
    ok(!$r, 'INT32_MIN+1 key rejected by put');
}
{
    my $r = hm_i32s_remove $map, $i32_min;
    ok(!$r, 'INT32_MIN key rejected by remove');
}
{
    my $r = hm_i32s_remove $map, $i32_min + 1;
    ok(!$r, 'INT32_MIN+1 key rejected by remove');
}

# empty map iteration
$map = Data::HashMap::I32S->new();
is_deeply([hm_i32s_keys $map], [], 'keys on empty map');

done_testing;
