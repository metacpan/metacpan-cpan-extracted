#!/usr/bin/env perl
use strict;
use warnings;
use POSIX ();
use Data::HashMap::Shared::II;

my $path = '/tmp/demo_multi.shm';
my $map = Data::HashMap::Shared::II->new($path, 100000);

shm_ii_put $map, 1, 0;

my $nprocs = 4;
my $iters  = 10000;

for my $n (1 .. $nprocs) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $child = Data::HashMap::Shared::II->new($path, 100000);
        for (1 .. $iters) {
            shm_ii_incr $child, 1;
        }
        POSIX::_exit(0);
    }
}

# wait for all children
while (wait() > 0) {}

my $total = shm_ii_get $map, 1;
my $expected = $nprocs * $iters;
print "Result: $total (expected $expected) - ",
      $total == $expected ? "OK" : "MISMATCH", "\n";

$map->unlink;
