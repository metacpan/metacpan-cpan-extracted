use strict;
use warnings;
use Test::More;

use Data::HashMap::I32A;

my $map = Data::HashMap::I32A->new();
ok(defined $map, 'new()');
isa_ok($map, 'Data::HashMap::I32A');

# put and get scalar
ok(hm_i32a_put $map, 1, "hello", 'put string');
is(hm_i32a_get $map, 1, "hello", 'get string');

# put and get arrayref
ok(hm_i32a_put $map, 2, [1,2,3], 'put arrayref');
is_deeply(hm_i32a_get $map, 2, [1,2,3], 'get arrayref');

# put and get hashref
ok(hm_i32a_put $map, 3, {a => 1, b => 2}, 'put hashref');
is_deeply(hm_i32a_get $map, 3, {a => 1, b => 2}, 'get hashref');

# overwrite
ok(hm_i32a_put $map, 1, "replaced", 'overwrite');
is(hm_i32a_get $map, 1, "replaced", 'get overwritten');

# undef value
ok(hm_i32a_put $map, 4, undef, 'put undef');
is(hm_i32a_get $map, 4, undef, 'get undef');
ok(hm_i32a_exists $map, 4, 'exists for undef value');

# exists and remove
ok(hm_i32a_exists $map, 1, 'exists true');
{
    my $e = hm_i32a_exists $map, 99;
    ok(!$e, 'exists false');
}
ok(hm_i32a_remove $map, 1, 'remove');
is(hm_i32a_get $map, 1, undef, 'get after remove');
{
    my $r = hm_i32a_remove $map, 1;
    ok(!$r, 'remove non-existent');
}

# size
is(hm_i32a_size $map, 3, 'size');

# sentinel key rejection (INT32_MIN and INT32_MIN+1 are reserved)
my $i32_min = -2147483648;
{
    my $r = hm_i32a_put $map, $i32_min, "x";
    ok(!$r, 'INT32_MIN key rejected by put');
}
{
    my $r = hm_i32a_put $map, $i32_min + 1, "x";
    ok(!$r, 'INT32_MIN+1 key rejected by put');
}

# keys, values, items
$map = Data::HashMap::I32A->new();
hm_i32a_put $map, 10, "ten";
hm_i32a_put $map, 20, "twenty";
my @keys = sort { $a <=> $b } hm_i32a_keys $map;
is_deeply(\@keys, [10, 20], 'keys');

my @vals = sort { $a cmp $b } (hm_i32a_values $map);
is_deeply(\@vals, ["ten", "twenty"], 'values');

my @items = hm_i32a_items $map;
my %h = @items;
is($h{10}, "ten", 'items k1');
is($h{20}, "twenty", 'items k2');

# refcount correctness
{
    my $map2 = Data::HashMap::I32A->new();
    {
        my @arr = (1, 2, 3);
        hm_i32a_put $map2, 1, \@arr;
    }
    my $ref = hm_i32a_get $map2, 1;
    is_deeply($ref, [1, 2, 3], 'ref survives scope exit');
}

# method dispatch
{
    my $m = Data::HashMap::I32A->new();
    $m->put(1, "one");
    is($m->get(1), "one", 'method dispatch put/get');
    is($m->size(), 1, 'method dispatch size');
    $m->remove(1);
    is($m->size(), 0, 'method dispatch remove');
}

# each iterator
{
    my $m = Data::HashMap::I32A->new();
    hm_i32a_put $m, 1, "a";
    hm_i32a_put $m, 2, "b";
    my %seen;
    while (my ($k, $v) = hm_i32a_each $m) {
        $seen{$k} = $v;
    }
    is_deeply(\%seen, {1 => "a", 2 => "b"}, 'each iterates all');
}

# LRU with refs
{
    my $lru = Data::HashMap::I32A->new(3);
    hm_i32a_put $lru, 1, [1];
    hm_i32a_put $lru, 2, [2];
    hm_i32a_put $lru, 3, [3];
    hm_i32a_put $lru, 4, [4];
    is(hm_i32a_get $lru, 1, undef, 'LRU eviction');
    is_deeply(hm_i32a_get $lru, 4, [4], 'LRU newest survives');
    is(hm_i32a_size $lru, 3, 'LRU size capped');
}

# TTL
{
    my $ttl = Data::HashMap::I32A->new(0, 1);
    hm_i32a_put $ttl, 1, [1,2,3];
    is(hm_i32a_size $ttl, 1, 'TTL size before expiry');
    sleep 2;
    is(hm_i32a_get $ttl, 1, undef, 'TTL expired');
}

# overwrite undef
{
    my $m = Data::HashMap::I32A->new();
    hm_i32a_put $m, 1, undef;
    hm_i32a_put $m, 1, "real";
    is(hm_i32a_get $m, 1, "real", 'overwrite undef');
}

done_testing;
