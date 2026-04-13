#!/usr/bin/env perl
# Connected components via BFS on an undirected shared graph
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Graph::Shared;
$| = 1;

my $g = Data::Graph::Shared->new(undef, 20, 40);

# build two disconnected components
# component 1: 0-1-2-3 (cycle)
my @n = map { $g->add_node($_ * 10) } 0..7;
$g->add_edge($n[0], $n[1]); $g->add_edge($n[1], $n[0]);
$g->add_edge($n[1], $n[2]); $g->add_edge($n[2], $n[1]);
$g->add_edge($n[2], $n[3]); $g->add_edge($n[3], $n[2]);
$g->add_edge($n[3], $n[0]); $g->add_edge($n[0], $n[3]);

# component 2: 4-5-6 (chain)
$g->add_edge($n[4], $n[5]); $g->add_edge($n[5], $n[4]);
$g->add_edge($n[5], $n[6]); $g->add_edge($n[6], $n[5]);

# node 7: isolated

printf "graph: %d nodes, %d edges\n\n", $g->node_count, $g->edge_count;

# BFS to find connected components
my %visited;
my $comp_id = 0;
for my $start ($g->nodes) {
    next if $visited{$start};
    $comp_id++;
    my @queue = ($start);
    my @members;
    while (@queue) {
        my $u = shift @queue;
        next if $visited{$u}++;
        push @members, $u;
        for my $pair ($g->neighbors($u)) {
            push @queue, $pair->[0] unless $visited{$pair->[0]};
        }
    }
    printf "component %d: nodes [%s]\n", $comp_id, join(', ', sort { $a <=> $b } @members);
}
printf "\ntotal: %d components\n", $comp_id;
