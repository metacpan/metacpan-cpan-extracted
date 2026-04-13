#!/usr/bin/env perl
# Topological sort (Kahn's algorithm) on a shared DAG
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Graph::Shared;
$| = 1;

my $g = Data::Graph::Shared->new(undef, 20, 30);

# build a DAG (task dependencies)
#   compile → link → package → deploy
#   test → package
#   lint → compile
my %tasks;
for my $name (qw(lint compile test link package deploy)) {
    $tasks{$name} = $g->add_node(0);
    printf "task '%s' = node %d\n", $name, $tasks{$name};
}

$g->add_edge($tasks{lint},    $tasks{compile});
$g->add_edge($tasks{compile}, $tasks{link});
$g->add_edge($tasks{link},    $tasks{package});
$g->add_edge($tasks{test},    $tasks{package});
$g->add_edge($tasks{package}, $tasks{deploy});

# compute in-degree
my @nodes = $g->nodes;
my %in_deg;
$in_deg{$_} = 0 for @nodes;
for my $u (@nodes) {
    for my $pair ($g->neighbors($u)) {
        $in_deg{$pair->[0]}++;
    }
}

# Kahn's algorithm
my @queue = grep { $in_deg{$_} == 0 } @nodes;
my @order;
my %name_of = reverse %tasks;

while (@queue) {
    my $u = shift @queue;
    push @order, $u;
    for my $pair ($g->neighbors($u)) {
        my $v = $pair->[0];
        $in_deg{$v}--;
        push @queue, $v if $in_deg{$v} == 0;
    }
}

printf "\ntopological order:\n";
for my $i (0..$#order) {
    printf "  %d. %s (node %d)\n", $i + 1, $name_of{$order[$i]} // "?", $order[$i];
}
printf "\nvalid: %s\n", scalar(@order) == scalar(@nodes) ? "yes" : "CYCLE DETECTED";
