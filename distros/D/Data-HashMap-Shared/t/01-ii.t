use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec ();

use POSIX ();
use Data::HashMap::Shared::II;

my $path = File::Temp::tempnam(File::Spec->tmpdir, 'shm_test') . '.shm';

# Basic CRUD
{
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    ok($map, 'created shared map');

    ok(shm_ii_put $map, 42, 100, 'put');
    is(shm_ii_get $map, 42, 100, 'get');
    ok(shm_ii_exists $map, 42, 'exists');
    is(shm_ii_size $map, 1, 'size');

    ok(shm_ii_put $map, 42, 200, 'update');
    is(shm_ii_get $map, 42, 200, 'get updated');

    ok(shm_ii_remove $map, 42, 'remove');
    ok(!defined(shm_ii_get $map, 42), 'get after remove');
    is(shm_ii_size $map, 0, 'size after remove');

    unlink $path;
}

# Multiple entries
{
    my $map = Data::HashMap::Shared::II->new($path, 1000);

    for my $i (1..50) {
        shm_ii_put $map, $i, $i * 10;
    }
    is(shm_ii_size $map, 50, 'size after 50 inserts');

    for my $i (1..50) {
        is(shm_ii_get $map, $i, $i * 10, "get $i");
    }

    unlink $path;
}

# Counters
{
    my $map = Data::HashMap::Shared::II->new($path, 1000);

    is(shm_ii_incr $map, 1, 1, 'incr creates entry');
    is(shm_ii_incr $map, 1, 2, 'incr again');
    is(shm_ii_decr $map, 1, 1, 'decr');
    is(shm_ii_incr_by $map, 1, 10, 11, 'incr_by');

    unlink $path;
}

# keys/values/items
{
    my $map = Data::HashMap::Shared::II->new($path, 1000);

    shm_ii_put $map, 1, 10;
    shm_ii_put $map, 2, 20;
    shm_ii_put $map, 3, 30;

    my @k = sort { $a <=> $b } shm_ii_keys $map;
    is_deeply(\@k, [1, 2, 3], 'keys');

    my @v = sort { $a <=> $b } shm_ii_values $map;
    is_deeply(\@v, [10, 20, 30], 'values');

    my @items = shm_ii_items $map;
    my %h;
    while (@items) {
        my ($k, $v) = splice @items, 0, 2;
        $h{$k} = $v;
    }
    is_deeply(\%h, {1 => 10, 2 => 20, 3 => 30}, 'items');

    unlink $path;
}

# each iterator
{
    my $map = Data::HashMap::Shared::II->new($path, 1000);

    shm_ii_put $map, 1, 10;
    shm_ii_put $map, 2, 20;

    my %got;
    while (my ($k, $v) = shm_ii_each $map) {
        $got{$k} = $v;
    }
    is_deeply(\%got, {1 => 10, 2 => 20}, 'each');

    # Second iteration should work after auto-reset
    %got = ();
    while (my ($k, $v) = shm_ii_each $map) {
        $got{$k} = $v;
    }
    is_deeply(\%got, {1 => 10, 2 => 20}, 'each second pass');

    unlink $path;
}

# clear
{
    my $map = Data::HashMap::Shared::II->new($path, 1000);

    shm_ii_put $map, 1, 10;
    shm_ii_put $map, 2, 20;
    shm_ii_clear $map;
    is(shm_ii_size $map, 0, 'size after clear');
    ok(!defined(shm_ii_get $map, 1), 'get after clear');

    unlink $path;
}

# to_hash
{
    my $map = Data::HashMap::Shared::II->new($path, 1000);

    shm_ii_put $map, 1, 10;
    shm_ii_put $map, 2, 20;

    my $href = shm_ii_to_hash $map;
    is_deeply($href, {1 => 10, 2 => 20}, 'to_hash');

    unlink $path;
}

# get_or_set
{
    my $map = Data::HashMap::Shared::II->new($path, 1000);

    is(shm_ii_get_or_set $map, 1, 42, 42, 'get_or_set inserts');
    is(shm_ii_get_or_set $map, 1, 99, 42, 'get_or_set returns existing');

    unlink $path;
}

# max_entries
{
    my $map = Data::HashMap::Shared::II->new($path, 100);
    my $me = shm_ii_max_entries $map;
    ok($me >= 100, 'max_entries >= requested');

    unlink $path;
}

# Method API
{
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    $map->put(42, 100);
    is($map->get(42), 100, 'method get');
    ok($map->exists(42), 'method exists');
    is($map->size(), 1, 'method size');
    $map->remove(42);
    ok(!defined $map->get(42), 'method remove');

    unlink $path;
}

# Cross-process sharing
{
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    shm_ii_put $map, 1, 100;

    my $pid = fork();
    if ($pid == 0) {
        my $child = Data::HashMap::Shared::II->new($path, 1000);
        shm_ii_incr $child, 1;
        shm_ii_put $child, 2, 200;
        POSIX::_exit(0);
    }
    waitpid($pid, 0);

    is(shm_ii_get $map, 1, 101, 'child increment visible');
    is(shm_ii_get $map, 2, 200, 'child insert visible');

    unlink $path;
}

# Opening a file with a mismatched variant should fail
{
    use Data::HashMap::Shared::SS;

    my $ii_path = File::Temp::tempnam(File::Spec->tmpdir, 'shm_test') . '.shm';
    my $map = Data::HashMap::Shared::II->new($ii_path, 100);
    shm_ii_put $map, 1, 42;
    undef $map;

    eval { Data::HashMap::Shared::SS->new($ii_path, 100) };
    like($@, qr/variant mismatch/, 'opening II file as SS croaks');

    unlink $ii_path;
}

done_testing;
