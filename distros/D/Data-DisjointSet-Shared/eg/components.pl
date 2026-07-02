#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
# Prefer a freshly built blib/ (picks up both lib and the compiled .so),
# fall back to lib/ or the installed module.
BEGIN {
    my $blib = "$FindBin::Bin/../blib";
    if (-d "$blib/arch") { require blib; blib->import($blib) }
    else { unshift @INC, "$FindBin::Bin/../lib" }
}
use Data::DisjointSet::Shared;

# Connected components of an undirected graph via union-find. We have a fixed
# set of vertices (0 .. N-1) and a fixed edge list; unioning the endpoints of
# every edge collapses each connected component into one disjoint set. We then
# report how many components there are and the size of each.

my $N = 10;   # vertices 0 .. 9

# A fixed edge list producing three components:
#   {0,1,2,3}, {4,5}, {6,7,8,9}
my @edges = (
    [0, 1], [1, 2], [2, 3],   # component A
    [4, 5],                    # component B
    [6, 7], [7, 8], [8, 9], [9, 6],   # component C (with a cycle 6-7-8-9-6)
);

my $d = Data::DisjointSet::Shared->new(undef, $N);
$d->union(@$_) for @edges;

printf "graph: %d vertices, %d edges\n", $N, scalar @edges;
printf "connected components: %d\n\n", $d->num_sets;

# Gather each component by its root, preserving the smallest member as a label.
my %members;
push @{ $members{ $d->find($_) } }, $_ for 0 .. $N - 1;

my $i = 1;
for my $root (sort { $a <=> $b } keys %members) {
    my @verts = sort { $a <=> $b } @{ $members{$root} };
    printf "  component %d: size %d  { %s }\n", $i++, scalar(@verts), join(', ', @verts);
}
