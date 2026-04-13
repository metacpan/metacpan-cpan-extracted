#!/usr/bin/env perl
# Dijkstra's shortest path using Graph + Heap together
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use lib "$FindBin::Bin/../../Data-Heap-Shared/blib/lib",
        "$FindBin::Bin/../../Data-Heap-Shared/blib/arch";
$| = 1;

eval { require Data::Graph::Shared; 1 } or die "Data::Graph::Shared required\n";
eval { require Data::Heap::Shared;  1 } or die "Data::Heap::Shared required (sibling)\n";

# build a small weighted graph
#   0 --2-- 1 --3-- 3
#   |       |       |
#   4       1       1
#   |       |       |
#   2 --5-- 4 --2-- 5

my $g = Data::Graph::Shared->new(undef, 10, 20);
my @n = map { $g->add_node($_) } 0..5;

my @edges = (
    [0,1,2], [0,2,4],
    [1,3,3], [1,4,1],
    [2,4,5],
    [3,5,1], [4,5,2],
);
$g->add_edge($n[$_->[0]], $n[$_->[1]], $_->[2]) for @edges;
# make undirected
$g->add_edge($n[$_->[1]], $n[$_->[0]], $_->[2]) for @edges;

printf "graph: %d nodes, %d edges\n\n", $g->node_count, $g->edge_count;

# Dijkstra from node 0
my $src = $n[0];
my %dist;
my %prev;
$dist{$src} = 0;

my $pq = Data::Heap::Shared->new(undef, 100);
$pq->push(0, $src);

while (!$pq->is_empty) {
    my ($d, $u) = $pq->pop;
    next if defined $dist{$u} && $d > $dist{$u};
    for my $pair ($g->neighbors($u)) {
        my ($v, $w) = @$pair;
        my $alt = $d + $w;
        if (!defined $dist{$v} || $alt < $dist{$v}) {
            $dist{$v} = $alt;
            $prev{$v} = $u;
            $pq->push($alt, $v);
        }
    }
}

printf "shortest paths from node %d:\n", $src;
for my $t (sort keys %dist) {
    my @path;
    my $cur = $t;
    while (defined $cur) {
        unshift @path, $cur;
        $cur = $prev{$cur};
    }
    printf "  to %d: dist=%d path=[%s]\n", $t, $dist{$t}, join('->', @path);
}
