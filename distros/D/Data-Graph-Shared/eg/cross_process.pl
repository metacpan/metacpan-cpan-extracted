#!/usr/bin/env perl
# Cross-process: parent builds graph, child reads and traverses
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::Graph::Shared;
$| = 1;

my $g = Data::Graph::Shared->new(undef, 10, 20);

my $a = $g->add_node(100);
my $b = $g->add_node(200);
my $c = $g->add_node(300);
$g->add_edge($a, $b, 5);
$g->add_edge($b, $c, 10);
printf "parent: built graph with %d nodes, %d edges\n", $g->node_count, $g->edge_count;

my $pid = fork // die;
if ($pid == 0) {
    printf "child:  node_count=%d edge_count=%d\n", $g->node_count, $g->edge_count;
    printf "child:  node %d data=%d\n", $a, $g->node_data($a);
    $g->each_neighbor($a, sub {
        printf "child:  %d -> %d weight=%d\n", $a, $_[0], $_[1];
    });
    # child adds a node
    my $d = $g->add_node(400);
    $g->add_edge($c, $d, 7);
    printf "child:  added node %d, edge_count=%d\n", $d, $g->edge_count;
    _exit(0);
}
waitpid($pid, 0);
printf "parent: after child, node_count=%d edge_count=%d\n",
    $g->node_count, $g->edge_count;
