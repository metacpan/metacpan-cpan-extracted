#!/usr/bin/env perl
# Cross-process: parent builds a k-d tree via memfd, children open the same fd
# and each scatter their own points into the one shared index.  The parent then
# queries the combined point cloud -- a fleet of workers populating a single
# spatial index, rebuilt once on the first query.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::KDTree::Shared;
$| = 1;

my $kids = 4;
my $per  = 25_000;
my $cap  = $kids * $per;

my $kd = Data::KDTree::Shared->new_memfd('kdtree-demo', 2, $cap);
my $fd = $kd->memfd;
printf "parent: created 2-D k-d tree (capacity %d) via memfd fd=%d\n", $kd->capacity, $fd;

my @pids;
for my $c (0 .. $kids - 1) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $child = Data::KDTree::Shared->new_from_fd($fd);
        my $seed = 1000 + $c * 7919;
        for my $i (1 .. $per) {
            $seed = ($seed * 1103515245 + 12345) & 0x7fffffff; my $x = $seed / 0x7fffffff * 1000;
            $seed = ($seed * 1103515245 + 12345) & 0x7fffffff; my $y = $seed / 0x7fffffff * 1000;
            $child->add([$x, $y], $c * $per + $i);   # globally unique id
        }
        _exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

printf "parent: after %d children added %d points each, count=%d\n\n", $kids, $per, $kd->count;

my @q = (500, 500);
my $near = $kd->nearest(\@q);
printf "nearest point to (%.0f, %.0f): #%d at distance %.3f\n", @q, $near->{id}, $near->{dist};
printf "points within radius 10 of centre: %d\n", scalar $kd->radius(\@q, 10);
printf "points in the central 50x50 box  : %d\n", scalar $kd->range([475, 475], [525, 525]);
