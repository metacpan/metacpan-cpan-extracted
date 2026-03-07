use strict;
use warnings;
use Test::More;

use Data::HashMap::SS;

my $map = Data::HashMap::SS->new();
ok(defined $map, 'new()');
isa_ok($map, 'Data::HashMap::SS');

# put and get
ok(hm_ss_put $map, "name", "Alice", 'put');
is(hm_ss_get $map, "name", "Alice", 'get');

ok(hm_ss_put $map, "city", "Berlin", 'put 2');
is(hm_ss_get $map, "city", "Berlin", 'get 2');

# overwrite
ok(hm_ss_put $map, "name", "Bob", 'overwrite');
is(hm_ss_get $map, "name", "Bob", 'get overwritten');

# exists
ok(hm_ss_exists $map, "name", 'exists true');
{
    my $e = hm_ss_exists $map, "missing";
    ok(!$e, 'exists false');
}

# remove
ok(hm_ss_remove $map, "name", 'remove');
is(hm_ss_get $map, "name", undef, 'get after remove');
{
    my $r = hm_ss_remove $map, "name";
    ok(!$r, 'remove non-existent');
}

# empty key/value
ok(hm_ss_put $map, "", "empty_key", 'empty key');
is(hm_ss_get $map, "", "empty_key", 'get empty key');

ok(hm_ss_put $map, "empty_val", "", 'empty value');
is(hm_ss_get $map, "empty_val", "", 'get empty value');

# UTF-8
{
    my $utf8_key = "\x{263A}";
    my $utf8_val = "\x{2603}";
    ok(hm_ss_put $map, $utf8_key, $utf8_val, 'put UTF-8');
    my $got = hm_ss_get $map, $utf8_key;
    is($got, $utf8_val, 'get UTF-8');
    ok(utf8::is_utf8($got), 'UTF-8 value flag');
    my @k = hm_ss_keys $map;
    my ($rk) = grep { $_ eq $utf8_key } @k;
    ok(utf8::is_utf8($rk), 'UTF-8 key flag');
}

# size, keys, items
$map = Data::HashMap::SS->new();
hm_ss_put $map, "a", "1";
hm_ss_put $map, "b", "2";
is(hm_ss_size $map, 2, 'size');

my @keys = sort { $a cmp $b } (hm_ss_keys $map);
is_deeply(\@keys, ["a", "b"], 'keys');

my @vals = sort { $a cmp $b } (hm_ss_values $map);
is_deeply(\@vals, ["1", "2"], 'values');

my @items = hm_ss_items $map;
my %h = @items;
is_deeply(\%h, {a => "1", b => "2"}, 'items');

# empty map iteration
$map = Data::HashMap::SS->new();
is_deeply([hm_ss_keys $map], [], 'keys on empty map');

done_testing;
