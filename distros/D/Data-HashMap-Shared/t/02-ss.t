use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec ();
use POSIX ();

use Data::HashMap::Shared::SS;

my $path = File::Temp::tempnam(File::Spec->tmpdir, 'shm_test') . '.shm';

# Basic CRUD
{
    my $map = Data::HashMap::Shared::SS->new($path, 1000);
    ok($map, 'created shared map');

    ok(shm_ss_put $map, "hello", "world", 'put');
    is(shm_ss_get $map, "hello", "world", 'get');
    ok(shm_ss_exists $map, "hello", 'exists');
    is(shm_ss_size $map, 1, 'size');

    ok(shm_ss_put $map, "hello", "updated", 'update');
    is(shm_ss_get $map, "hello", "updated", 'get updated');

    ok(shm_ss_remove $map, "hello", 'remove');
    ok(!defined(shm_ss_get $map, "hello"), 'get after remove');
    is(shm_ss_size $map, 0, 'size after remove');

    unlink $path;
}

# UTF-8
{
    my $map = Data::HashMap::Shared::SS->new($path, 1000);

    my $key = "\x{263A}";    # smiley
    my $val = "\x{2603}";    # snowman
    shm_ss_put $map, $key, $val;
    my $got = shm_ss_get $map, $key;
    is($got, $val, 'utf8 value');
    ok(utf8::is_utf8($got), 'utf8 flag preserved');

    unlink $path;
}

# keys/values/items
{
    my $map = Data::HashMap::Shared::SS->new($path, 1000);

    shm_ss_put $map, "a", "1";
    shm_ss_put $map, "b", "2";
    shm_ss_put $map, "c", "3";

    my @k = sort (shm_ss_keys $map);
    is_deeply(\@k, ["a", "b", "c"], 'keys');

    my @v = sort (shm_ss_values $map);
    is_deeply(\@v, ["1", "2", "3"], 'values');

    my @items = shm_ss_items $map;
    my %from_items = @items;
    is_deeply(\%from_items, {a => "1", b => "2", c => "3"}, 'items');

    unlink $path;
}

# each
{
    my $map = Data::HashMap::Shared::SS->new($path, 1000);

    shm_ss_put $map, "x", "10";
    shm_ss_put $map, "y", "20";

    my %got;
    while (my ($k, $v) = shm_ss_each $map) {
        $got{$k} = $v;
    }
    is_deeply(\%got, {x => "10", y => "20"}, 'each');

    unlink $path;
}

# to_hash
{
    my $map = Data::HashMap::Shared::SS->new($path, 1000);

    shm_ss_put $map, "a", "1";
    shm_ss_put $map, "b", "2";

    my $href = shm_ss_to_hash $map;
    is_deeply($href, {a => "1", b => "2"}, 'to_hash');

    unlink $path;
}

# get_or_set
{
    my $map = Data::HashMap::Shared::SS->new($path, 1000);

    is(shm_ss_get_or_set $map, "k", "default", "default", 'get_or_set inserts');
    is(shm_ss_get_or_set $map, "k", "other", "default", 'get_or_set returns existing');

    unlink $path;
}

# clear
{
    my $map = Data::HashMap::Shared::SS->new($path, 1000);

    shm_ss_put $map, "a", "1";
    shm_ss_put $map, "b", "2";
    shm_ss_clear $map;
    is(shm_ss_size $map, 0, 'size after clear');

    unlink $path;
}

# Cross-process
{
    my $map = Data::HashMap::Shared::SS->new($path, 1000);
    shm_ss_put $map, "shared", "parent";

    my $pid = fork();
    if ($pid == 0) {
        my $child = Data::HashMap::Shared::SS->new($path, 1000);
        shm_ss_put $child, "shared", "child";
        shm_ss_put $child, "new", "from_child";
        POSIX::_exit(0);
    }
    waitpid($pid, 0);

    is(shm_ss_get $map, "shared", "child", 'child update visible');
    is(shm_ss_get $map, "new", "from_child", 'child insert visible');

    unlink $path;
}

# Method API
{
    my $map = Data::HashMap::Shared::SS->new($path, 1000);
    $map->put("k", "v");
    is($map->get("k"), "v", 'method get');
    $map->remove("k");
    ok(!defined $map->get("k"), 'method remove');

    unlink $path;
}

done_testing;
