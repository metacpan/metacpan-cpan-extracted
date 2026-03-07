use strict;
use warnings;
use Test::More;

use Data::HashMap::SA;

my $map = Data::HashMap::SA->new();
ok(defined $map, 'new()');
isa_ok($map, 'Data::HashMap::SA');

# put and get scalar
ok(hm_sa_put $map, "k1", "hello", 'put string');
is(hm_sa_get $map, "k1", "hello", 'get string');

# put and get arrayref
ok(hm_sa_put $map, "k2", [1,2,3], 'put arrayref');
is_deeply(hm_sa_get $map, "k2", [1,2,3], 'get arrayref');

# put and get hashref
ok(hm_sa_put $map, "k3", {a => 1, b => 2}, 'put hashref');
is_deeply(hm_sa_get $map, "k3", {a => 1, b => 2}, 'get hashref');

# overwrite
ok(hm_sa_put $map, "k1", "replaced", 'overwrite');
is(hm_sa_get $map, "k1", "replaced", 'get overwritten');

# undef value
ok(hm_sa_put $map, "k4", undef, 'put undef');
is(hm_sa_get $map, "k4", undef, 'get undef');
ok(hm_sa_exists $map, "k4", 'exists for undef value');

# exists and remove
ok(hm_sa_exists $map, "k1", 'exists true');
{
    my $e = hm_sa_exists $map, "none";
    ok(!$e, 'exists false');
}
ok(hm_sa_remove $map, "k1", 'remove');
is(hm_sa_get $map, "k1", undef, 'get after remove');
{
    my $r = hm_sa_remove $map, "k1";
    ok(!$r, 'remove non-existent');
}

# size — keys k2, k3, k4 (k1 was removed)
is(hm_sa_size $map, 3, 'size');

# UTF-8 keys
{
    my $utf8_key = "\x{263A}\x{2603}";
    ok(hm_sa_put $map, $utf8_key, "smiley", 'put UTF-8 key');
    is(hm_sa_get $map, $utf8_key, "smiley", 'get UTF-8 key');
    ok(hm_sa_exists $map, $utf8_key, 'exists UTF-8 key');
}

# keys, values, items
$map = Data::HashMap::SA->new();
hm_sa_put $map, "a", "one";
hm_sa_put $map, "b", "two";
my @keys = sort (hm_sa_keys $map);
is_deeply(\@keys, ["a", "b"], 'keys');

my @vals = sort (hm_sa_values $map);
is_deeply(\@vals, ["one", "two"], 'values');

my @items = hm_sa_items $map;
my %h = @items;
is($h{a}, "one", 'items k1');
is($h{b}, "two", 'items k2');

# empty map iteration
$map = Data::HashMap::SA->new();
is_deeply([hm_sa_keys $map], [], 'keys on empty map');

# refcount correctness — stored refs should survive scope
{
    my $map2 = Data::HashMap::SA->new();
    {
        my @arr = (1, 2, 3);
        hm_sa_put $map2, "ref", \@arr;
    }
    my $ref = hm_sa_get $map2, "ref";
    is_deeply($ref, [1, 2, 3], 'ref survives scope exit');
}

# nested refs
{
    my $map3 = Data::HashMap::SA->new();
    my $complex = { list => [1, {deep => "value"}], num => 42 };
    hm_sa_put $map3, "cx", $complex;
    my $got = hm_sa_get $map3, "cx";
    is_deeply($got, $complex, 'nested refs preserved');
    is($got->{list}[1]{deep}, "value", 'deep access works');
}

# method dispatch
{
    my $m = Data::HashMap::SA->new();
    $m->put("x", "one");
    is($m->get("x"), "one", 'method dispatch put/get');
    is($m->size(), 1, 'method dispatch size');
    ok($m->exists("x"), 'method dispatch exists');
    $m->remove("x");
    is($m->size(), 0, 'method dispatch remove');
}

# each iterator
{
    my $m = Data::HashMap::SA->new();
    hm_sa_put $m, "a", "one";
    hm_sa_put $m, "b", "two";
    my %seen;
    while (my ($k, $v) = hm_sa_each $m) {
        $seen{$k} = $v;
    }
    is_deeply(\%seen, {a => "one", b => "two"}, 'each iterates all');
}

# LRU with refs
{
    my $lru = Data::HashMap::SA->new(3);
    hm_sa_put $lru, "a", [1];
    hm_sa_put $lru, "b", [2];
    hm_sa_put $lru, "c", [3];
    hm_sa_put $lru, "d", [4];  # should evict "a"
    is(hm_sa_get $lru, "a", undef, 'LRU eviction');
    is_deeply(hm_sa_get $lru, "d", [4], 'LRU newest survives');
    is(hm_sa_size $lru, 3, 'LRU size capped');
}

# code ref
{
    my $m = Data::HashMap::SA->new();
    my $cb = sub { return 42 };
    hm_sa_put $m, "fn", $cb;
    my $got = hm_sa_get $m, "fn";
    is(ref $got, 'CODE', 'code ref stored');
    is($got->(), 42, 'code ref callable');
}

# blessed object
{
    my $m = Data::HashMap::SA->new();
    my $obj = bless { x => 1 }, 'Foo';
    hm_sa_put $m, "obj", $obj;
    my $got = hm_sa_get $m, "obj";
    isa_ok($got, 'Foo', 'blessed object preserved');
    is($got->{x}, 1, 'object data intact');
}

# TTL — expired SV* values should be freed correctly
{
    my $ttl = Data::HashMap::SA->new(0, 1);
    hm_sa_put $ttl, "a", [1,2,3];
    hm_sa_put $ttl, "b", {x => 1};
    is(hm_sa_size $ttl, 2, 'TTL size before expiry');
    sleep 2;
    is(hm_sa_get $ttl, "a", undef, 'TTL expired get returns undef');
    my @k = hm_sa_keys $ttl;
    is(scalar @k, 0, 'TTL expired keys empty');
}

# overwrite undef value with real value
{
    my $m = Data::HashMap::SA->new();
    hm_sa_put $m, "x", undef;
    is(hm_sa_get $m, "x", undef, 'undef stored');
    hm_sa_put $m, "x", "real";
    is(hm_sa_get $m, "x", "real", 'overwrite undef with real value');
}

done_testing;
