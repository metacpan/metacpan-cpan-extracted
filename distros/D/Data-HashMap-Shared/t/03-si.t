use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec ();
use POSIX ();

use Data::HashMap::Shared::SI;

my $path = File::Temp::tempnam(File::Spec->tmpdir, 'shm_test') . '.shm';

# Basic CRUD
{
    my $map = Data::HashMap::Shared::SI->new($path, 1000);

    ok(shm_si_put $map, "counter", 42, 'put');
    is(shm_si_get $map, "counter", 42, 'get');
    ok(shm_si_exists $map, "counter", 'exists');
    is(shm_si_size $map, 1, 'size');

    ok(shm_si_remove $map, "counter", 'remove');
    ok(!defined(shm_si_get $map, "counter"), 'get after remove');

    unlink $path;
}

# Counters
{
    my $map = Data::HashMap::Shared::SI->new($path, 1000);

    is(shm_si_incr $map, "hits", 1, 'incr creates');
    is(shm_si_incr $map, "hits", 2, 'incr again');
    is(shm_si_decr $map, "hits", 1, 'decr');
    is(shm_si_incr_by $map, "hits", 100, 101, 'incr_by');

    unlink $path;
}

# Cross-process atomic counters
{
    my $map = Data::HashMap::Shared::SI->new($path, 1000);
    shm_si_put $map, "c", 0;

    my @pids;
    for (1..4) {
        my $pid = fork();
        if ($pid == 0) {
            my $child = Data::HashMap::Shared::SI->new($path, 1000);
            for (1..100) {
                shm_si_incr $child, "c";
            }
            POSIX::_exit(0);
        }
        push @pids, $pid;
    }
    waitpid($_, 0) for @pids;

    is(shm_si_get $map, "c", 400, 'atomic counter across 4 processes');

    unlink $path;
}

# keys/values/items
{
    my $map = Data::HashMap::Shared::SI->new($path, 1000);

    shm_si_put $map, "a", 1;
    shm_si_put $map, "b", 2;

    my @k = sort (shm_si_keys $map);
    is_deeply(\@k, ["a", "b"], 'keys');

    my @v = sort { $a <=> $b } shm_si_values $map;
    is_deeply(\@v, [1, 2], 'values');

    unlink $path;
}

# to_hash
{
    my $map = Data::HashMap::Shared::SI->new($path, 1000);

    shm_si_put $map, "x", 10;
    shm_si_put $map, "y", 20;

    my $href = shm_si_to_hash $map;
    is_deeply($href, {x => 10, y => 20}, 'to_hash');

    unlink $path;
}

done_testing;
