#!/usr/bin/env perl
# Basic graph: add nodes/edges, query neighbors, remove nodes
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Graph::Shared;
$| = 1;

my $g = Data::Graph::Shared->new(undef, 10, 20);

my $a = $g->add_node(1);
my $b = $g->add_node(2);
my $c = $g->add_node(3);
my $d = $g->add_node(4);

$g->add_edge($a, $b, 10);
$g->add_edge($a, $c, 5);
$g->add_edge($b, $d, 3);
$g->add_edge($c, $d, 8);

printf "graph: %d nodes, %d edges\n\n", $g->node_count, $g->edge_count;

for my $n ($g->nodes) {
    printf "node %d (data=%d): ", $n, $g->node_data($n);
    my @nbrs = $g->neighbors($n);
    if (@nbrs) {
        printf "%s\n", join(', ', map { "->$_->[0] w=$_->[1]" } @nbrs);
    } else {
        printf "(no outgoing edges)\n";
    }
}

printf "\nremove node %d\n", $b;
$g->remove_node($b);
printf "graph: %d nodes, %d edges\n", $g->node_count, $g->edge_count;
