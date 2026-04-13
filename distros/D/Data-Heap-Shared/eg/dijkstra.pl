#!/usr/bin/env perl
# Dijkstra's shortest path using shared Heap as priority queue
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Heap::Shared;
$| = 1;

# adjacency list (node => [[neighbor, weight], ...])
my %graph = (
    0 => [[1,4], [2,1]],
    1 => [[3,1]],
    2 => [[1,2], [3,5]],
    3 => [[4,3]],
    4 => [],
);

my $src = 0;
my %dist = ($src => 0);
my %prev;

my $pq = Data::Heap::Shared->new(undef, 100);
$pq->push(0, $src);

while (!$pq->is_empty) {
    my ($d, $u) = $pq->pop;
    next if $d > ($dist{$u} // 1e18);
    for my $edge (@{$graph{$u} // []}) {
        my ($v, $w) = @$edge;
        my $alt = $d + $w;
        if (!defined $dist{$v} || $alt < $dist{$v}) {
            $dist{$v} = $alt;
            $prev{$v} = $u;
            $pq->push($alt, $v);
        }
    }
}

printf "shortest paths from node %d:\n", $src;
for my $t (sort { $a <=> $b } keys %dist) {
    my @path;
    my $cur = $t;
    while (defined $cur) { unshift @path, $cur; $cur = $prev{$cur} }
    printf "  to %d: dist=%d path=[%s]\n", $t, $dist{$t}, join('->', @path);
}
