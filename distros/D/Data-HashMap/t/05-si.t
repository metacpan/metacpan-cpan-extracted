use strict;
use warnings;
use Test::More;

use Data::HashMap::SI;

my $map = Data::HashMap::SI->new();
ok(defined $map, 'new()');
isa_ok($map, 'Data::HashMap::SI');

# put and get
ok(hm_si_put $map, "hello", 42, 'put');
is(hm_si_get $map, "hello", 42, 'get');

ok(hm_si_put $map, "world", 100, 'put 2');
is(hm_si_get $map, "world", 100, 'get 2');

# overwrite
ok(hm_si_put $map, "hello", 0, 'overwrite');
is(hm_si_get $map, "hello", 0, 'get overwritten');

# exists
ok(hm_si_exists $map, "hello", 'exists true');
{
    my $e = hm_si_exists $map, "missing";
    ok(!$e, 'exists false');
}

# remove
ok(hm_si_remove $map, "hello", 'remove');
is(hm_si_get $map, "hello", undef, 'get after remove');
{
    my $r = hm_si_remove $map, "hello";
    ok(!$r, 'remove non-existent');
}

# incr
is(hm_si_incr $map, "counter", 1, 'incr new');
is(hm_si_incr $map, "counter", 2, 'incr again');

# decr
is(hm_si_decr $map, "down", -1, 'decr new');

# incr_by
is(hm_si_incr_by $map, "by", 10, 10, 'incr_by 10');
is(hm_si_incr_by $map, "by", -3, 7, 'incr_by -3');

# empty string key
ok(hm_si_put $map, "", 999, 'empty string key put');
is(hm_si_get $map, "", 999, 'empty string key get');
ok(hm_si_remove $map, "", 'empty string key remove');

# UTF-8 key
my $utf8 = "\x{263A}";
hm_si_put $map, $utf8, 42;
is(hm_si_get $map, $utf8, 42, 'UTF-8 key');
{
    my @k = hm_si_keys $map;
    my ($utf_key) = grep { $_ eq $utf8 } @k;
    ok(utf8::is_utf8($utf_key), 'UTF-8 key flag preserved in keys()');
    my @it = hm_si_items $map;
    my %h2 = @it;
    my ($ik) = grep { $_ eq $utf8 } keys %h2;
    ok(utf8::is_utf8($ik), 'UTF-8 key flag preserved in items()');
}

# size
$map = Data::HashMap::SI->new();
hm_si_put $map, "a", 1;
hm_si_put $map, "b", 2;
is(hm_si_size $map, 2, 'size');

# keys
my @keys = sort { $a cmp $b } (hm_si_keys $map);
is_deeply(\@keys, ["a", "b"], 'keys');

# values
my @vals = sort { $a <=> $b } hm_si_values $map;
is_deeply(\@vals, [1, 2], 'values');

# items
my @items = hm_si_items $map;
my %h = @items;
is($h{a}, 1, 'items a');
is($h{b}, 2, 'items b');

# loop incr
$map = Data::HashMap::SI->new();
for (1 .. 5) { hm_si_incr $map, "loop"; }
is(hm_si_get $map, "loop", 5, 'loop incr');

# overflow protection
$map = Data::HashMap::SI->new();
hm_si_put $map, "max", 9223372036854775806;
is(hm_si_incr $map, "max", 9223372036854775807, 'incr to INT64_MAX');
eval { hm_si_incr $map, "max" };
like($@, qr/increment failed/, 'incr at INT64_MAX croaks');

hm_si_put $map, "min", -9223372036854775807;
is(hm_si_decr $map, "min", -9223372036854775808, 'decr to INT64_MIN');
eval { hm_si_decr $map, "min" };
like($@, qr/decrement failed/, 'decr at INT64_MIN croaks');

hm_si_put $map, "oflow", 9223372036854775800;
eval { hm_si_incr_by $map, "oflow", 100 };
like($@, qr/incr_by failed/, 'incr_by overflow croaks');

hm_si_put $map, "uflow", -9223372036854775800;
eval { hm_si_incr_by $map, "uflow", -100 };
like($@, qr/incr_by failed/, 'incr_by underflow croaks');

# incr_by with delta=0
$map = Data::HashMap::SI->new();
is(hm_si_incr_by $map, "z0", 0, 0, 'incr_by 0 on new key');
hm_si_put $map, "z1", 42;
is(hm_si_incr_by $map, "z1", 0, 42, 'incr_by 0 on existing key');

# put then incr on same key
$map = Data::HashMap::SI->new();
hm_si_put $map, "pi", 5;
is(hm_si_incr $map, "pi", 6, 'incr after put');

# empty map iteration
$map = Data::HashMap::SI->new();
is_deeply([hm_si_keys $map], [], 'keys on empty map');

done_testing;
