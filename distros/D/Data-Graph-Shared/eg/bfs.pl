#!/usr/bin/env perl
# BFS traversal on a shared graph
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Graph::Shared;
$| = 1;

my $g = Data::Graph::Shared->new(undef, 20, 40);

# build a tree-like graph
#       0
#      / \
#     1   2
#    / \   \
#   3   4   5
my @n = map { $g->add_node($_ * 10) } 0..5;
$g->add_edge($n[0], $n[1]);
$g->add_edge($n[0], $n[2]);
$g->add_edge($n[1], $n[3]);
$g->add_edge($n[1], $n[4]);
$g->add_edge($n[2], $n[5]);

printf "BFS from node %d:\n", $n[0];
my @queue = ($n[0]);
my %visited = ($n[0] => 1);
my $level = 0;
while (@queue) {
    printf "  level %d: %s\n", $level,
        join(' ', map { sprintf "%d(data=%d)", $_, $g->node_data($_) } @queue);
    my @next;
    for my $u (@queue) {
        for my $pair ($g->neighbors($u)) {
            my $v = $pair->[0];
            next if $visited{$v}++;
            push @next, $v;
        }
    }
    @queue = @next;
    $level++;
}
