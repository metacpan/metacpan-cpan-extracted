use strict;
use warnings;
use Test::More;

use Data::HashMap::I16S;

my $map = Data::HashMap::I16S->new();
ok(defined $map, 'new()');
isa_ok($map, 'Data::HashMap::I16S');

# put and get (keyword)
ok(hm_i16s_put $map, 1, "hello", 'put');
is(hm_i16s_get $map, 1, "hello", 'get');

# method dispatch
ok($map->put(2, "world"), 'method put');
is($map->get(2), "world", 'method get');
ok($map->exists(2), 'method exists');
is($map->size(), 2, 'method size');

# overwrite
ok(hm_i16s_put $map, 1, "updated", 'overwrite');
is(hm_i16s_get $map, 1, "updated", 'get overwritten');

# exists
ok(hm_i16s_exists $map, 1, 'exists true');
{
    my $e = hm_i16s_exists $map, 99;
    ok(!$e, 'exists false');
}

# remove
ok(hm_i16s_remove $map, 1, 'remove');
is(hm_i16s_get $map, 1, undef, 'get after remove');
{
    my $r = hm_i16s_remove $map, 1;
    ok(!$r, 'remove non-existent');
}

# UTF-8 values
my $utf8_val = "\x{263A}";  # smiley face
ok(hm_i16s_put $map, 10, $utf8_val, 'put utf8 value');
my $got = hm_i16s_get $map, 10;
is($got, $utf8_val, 'get utf8 value');
ok(utf8::is_utf8($got), 'utf8 flag preserved');

# size
is(hm_i16s_size $map, 2, 'size');

# keys, values, items
$map = Data::HashMap::I16S->new();
hm_i16s_put $map, 1, "a";
hm_i16s_put $map, 2, "b";

my @keys = sort { $a <=> $b } (hm_i16s_keys $map);
is_deeply(\@keys, [1, 2], 'keys');

my @vals = sort (hm_i16s_values $map);
is_deeply(\@vals, ["a", "b"], 'values');

my @items = hm_i16s_items $map;
my %h = @items;
is($h{1}, "a", 'items k1');
is($h{2}, "b", 'items k2');

# sentinel key rejection
my $i16_min = -32768;
{
    my $r = hm_i16s_put $map, $i16_min, "x";
    ok(!$r, 'INT16_MIN key rejected by put');
}
is(hm_i16s_get $map, $i16_min, undef, 'INT16_MIN key rejected by get');
{
    my $e = hm_i16s_exists $map, $i16_min;
    ok(!$e, 'INT16_MIN key rejected by exists');
}
{
    my $r = hm_i16s_put $map, $i16_min + 1, "x";
    ok(!$r, 'INT16_MIN+1 key rejected by put');
}
{
    my $r = hm_i16s_remove $map, $i16_min;
    ok(!$r, 'INT16_MIN key rejected by remove');
}
{
    my $r = hm_i16s_remove $map, $i16_min + 1;
    ok(!$r, 'INT16_MIN+1 key rejected by remove');
}

# empty map
$map = Data::HashMap::I16S->new();
is_deeply([hm_i16s_keys $map], [], 'keys on empty map');
is(hm_i16s_size $map, 0, 'size of empty map');

done_testing;
