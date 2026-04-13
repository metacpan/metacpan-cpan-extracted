#!/usr/bin/env perl
# Simple PageRank on a shared graph (iterative power method)
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Graph::Shared;
$| = 1;

my $g = Data::Graph::Shared->new(undef, 20, 40);

# build a small web graph
#   0 → 1, 2
#   1 → 2
#   2 → 0
#   3 → 0, 2
my @n = map { $g->add_node(0) } 0..3;
$g->add_edge($n[0], $n[1]);
$g->add_edge($n[0], $n[2]);
$g->add_edge($n[1], $n[2]);
$g->add_edge($n[2], $n[0]);
$g->add_edge($n[3], $n[0]);
$g->add_edge($n[3], $n[2]);

my $N = $g->node_count;
my $d = 0.85;  # damping factor
my @rank = (1.0 / $N) x $N;
my @nodes = $g->nodes;

printf "PageRank (damping=%.2f, %d nodes, %d edges):\n\n", $d, $N, $g->edge_count;

for my $iter (1..20) {
    my @new_rank = ((1.0 - $d) / $N) x $N;
    for my $u (@nodes) {
        my $deg = $g->degree($u);
        next unless $deg > 0;
        my $share = $rank[$u] * $d / $deg;
        for my $pair ($g->neighbors($u)) {
            $new_rank[$pair->[0]] += $share;
        }
    }
    my $diff = 0;
    $diff += abs($new_rank[$_] - $rank[$_]) for 0..$#rank;
    @rank = @new_rank;
    printf "  iter %2d: diff=%.6f\n", $iter, $diff if $iter <= 5 || $diff < 0.0001;
    last if $diff < 0.0001;
}

printf "\nfinal ranks:\n";
for my $n (@nodes) {
    printf "  node %d: %.4f\n", $n, $rank[$n];
}
