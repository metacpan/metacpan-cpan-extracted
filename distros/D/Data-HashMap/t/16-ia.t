use strict;
use warnings;
use Test::More;

use Data::HashMap::IA;

my $map = Data::HashMap::IA->new();
ok(defined $map, 'new()');
isa_ok($map, 'Data::HashMap::IA');

# put and get scalar
ok(hm_ia_put $map, 1, "hello", 'put string');
is(hm_ia_get $map, 1, "hello", 'get string');

# put and get arrayref
ok(hm_ia_put $map, 2, [1,2,3], 'put arrayref');
is_deeply(hm_ia_get $map, 2, [1,2,3], 'get arrayref');

# put and get hashref
ok(hm_ia_put $map, 3, {a => 1, b => 2}, 'put hashref');
is_deeply(hm_ia_get $map, 3, {a => 1, b => 2}, 'get hashref');

# overwrite — old value should be freed
ok(hm_ia_put $map, 1, "replaced", 'overwrite');
is(hm_ia_get $map, 1, "replaced", 'get overwritten');

# undef value
ok(hm_ia_put $map, 4, undef, 'put undef');
is(hm_ia_get $map, 4, undef, 'get undef');
ok(hm_ia_exists $map, 4, 'exists for undef value');

# exists and remove
ok(hm_ia_exists $map, 1, 'exists true');
{
    my $e = hm_ia_exists $map, 99;
    ok(!$e, 'exists false');
}
ok(hm_ia_remove $map, 1, 'remove');
is(hm_ia_get $map, 1, undef, 'get after remove');
{
    my $r = hm_ia_remove $map, 1;
    ok(!$r, 'remove non-existent');
}

# size — keys 2, 3, 4 (key 1 was removed)
is(hm_ia_size $map, 3, 'size');

# keys, values, items
$map = Data::HashMap::IA->new();
hm_ia_put $map, 10, "ten";
hm_ia_put $map, 20, "twenty";
my @keys = sort { $a <=> $b } hm_ia_keys $map;
is_deeply(\@keys, [10, 20], 'keys');

my @vals = sort { $a cmp $b } (hm_ia_values $map);
is_deeply(\@vals, ["ten", "twenty"], 'values');

my @items = hm_ia_items $map;
my %h = @items;
is($h{10}, "ten", 'items k1');
is($h{20}, "twenty", 'items k2');

# sentinel key rejection (INT64_MIN and INT64_MIN+1 are reserved)
my $i64_min = -9223372036854775808;
{
    my $r = hm_ia_put $map, $i64_min, "x";
    ok(!$r, 'INT64_MIN key rejected by put');
}
is(hm_ia_get $map, $i64_min, undef, 'INT64_MIN key rejected by get');
{
    my $r = hm_ia_put $map, $i64_min + 1, "x";
    ok(!$r, 'INT64_MIN+1 key rejected by put');
}

# empty map iteration
$map = Data::HashMap::IA->new();
is_deeply([hm_ia_keys $map], [], 'keys on empty map');

# refcount correctness — stored refs should survive
{
    my $map2 = Data::HashMap::IA->new();
    {
        my @arr = (1, 2, 3);
        hm_ia_put $map2, 1, \@arr;
    }
    # @arr is out of scope but refcount should keep it alive
    my $ref = hm_ia_get $map2, 1;
    is_deeply($ref, [1, 2, 3], 'ref survives scope exit');
}

# nested refs
{
    my $map3 = Data::HashMap::IA->new();
    my $complex = { list => [1, {deep => "value"}], num => 42 };
    hm_ia_put $map3, 1, $complex;
    my $got = hm_ia_get $map3, 1;
    is_deeply($got, $complex, 'nested refs preserved');
    is($got->{list}[1]{deep}, "value", 'deep access works');
}

# method dispatch
{
    my $m = Data::HashMap::IA->new();
    $m->put(1, "one");
    is($m->get(1), "one", 'method dispatch put/get');
    is($m->size(), 1, 'method dispatch size');
    ok($m->exists(1), 'method dispatch exists');
    $m->remove(1);
    is($m->size(), 0, 'method dispatch remove');
}

# each iterator
{
    my $m = Data::HashMap::IA->new();
    hm_ia_put $m, 1, "a";
    hm_ia_put $m, 2, "b";
    my %seen;
    while (my ($k, $v) = hm_ia_each $m) {
        $seen{$k} = $v;
    }
    is_deeply(\%seen, {1 => "a", 2 => "b"}, 'each iterates all');
}

# LRU with refs
{
    my $lru = Data::HashMap::IA->new(3);
    hm_ia_put $lru, 1, [1];
    hm_ia_put $lru, 2, [2];
    hm_ia_put $lru, 3, [3];
    hm_ia_put $lru, 4, [4];  # should evict key 1
    is(hm_ia_get $lru, 1, undef, 'LRU eviction');
    is_deeply(hm_ia_get $lru, 4, [4], 'LRU newest survives');
    is(hm_ia_size $lru, 3, 'LRU size capped');
}

# TTL — expired SV* values should be freed correctly
{
    my $ttl = Data::HashMap::IA->new(0, 1);
    hm_ia_put $ttl, 1, [1,2,3];
    hm_ia_put $ttl, 2, {a => 1};
    is(hm_ia_size $ttl, 2, 'TTL size before expiry');
    sleep 2;
    is(hm_ia_get $ttl, 1, undef, 'TTL expired get returns undef');
    my @k = hm_ia_keys $ttl;
    is(scalar @k, 0, 'TTL expired keys empty');
}

# overwrite undef value with real value
{
    my $m = Data::HashMap::IA->new();
    hm_ia_put $m, 1, undef;
    is(hm_ia_get $m, 1, undef, 'undef stored');
    hm_ia_put $m, 1, "real";
    is(hm_ia_get $m, 1, "real", 'overwrite undef with real value');
}

done_testing;
