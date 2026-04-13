#!/usr/bin/env perl
# Dependency graph: shared across processes for parallel build scheduling
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::Graph::Shared;
$| = 1;

my $g = Data::Graph::Shared->new(undef, 20, 30);

# model a build dependency graph
my %pkg;
for my $name (qw(libc libm libpthread openssl zlib curl nginx app)) {
    $pkg{$name} = $g->add_node(0);
}

# dependencies (edge = "must build before")
$g->add_edge($pkg{libc}, $pkg{libm});
$g->add_edge($pkg{libc}, $pkg{libpthread});
$g->add_edge($pkg{libc}, $pkg{zlib});
$g->add_edge($pkg{libm}, $pkg{openssl});
$g->add_edge($pkg{zlib}, $pkg{openssl});
$g->add_edge($pkg{openssl}, $pkg{curl});
$g->add_edge($pkg{libpthread}, $pkg{curl});
$g->add_edge($pkg{curl}, $pkg{nginx});
$g->add_edge($pkg{nginx}, $pkg{app});

printf "build graph: %d packages, %d dependencies\n\n", $g->node_count, $g->edge_count;

# child process reads the graph and computes build order
my $pid = fork // die;
if ($pid == 0) {
    my %name_of = reverse %pkg;
    my @nodes = $g->nodes;
    my %in_deg;
    $in_deg{$_} = 0 for @nodes;
    for my $u (@nodes) {
        $in_deg{$_->[0]}++ for $g->neighbors($u);
    }

    my @ready = sort grep { $in_deg{$_} == 0 } @nodes;
    my @order;
    while (@ready) {
        my $u = shift @ready;
        push @order, $u;
        for my $pair ($g->neighbors($u)) {
            $in_deg{$pair->[0]}--;
            push @ready, $pair->[0] if $in_deg{$pair->[0]} == 0;
        }
        @ready = sort @ready;
    }
    printf "child build order:\n";
    printf "  %d. %s\n", $_ + 1, $name_of{$order[$_]} for 0..$#order;
    _exit(0);
}
waitpid($pid, 0);
