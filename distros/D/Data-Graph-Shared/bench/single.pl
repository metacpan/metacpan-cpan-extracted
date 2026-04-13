#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Time::HiRes qw(time);
use Data::Graph::Shared;

my $N = shift || 10_000;

sub bench {
    my ($label, $n, $code) = @_;
    my $t0 = time;
    $code->();
    my $dt = time - $t0;
    printf "  %-35s %10.0f/s  (%.3fs)\n", $label, $n / $dt, $dt;
}

printf "Data::Graph::Shared benchmark (%d ops)\n\n", $N;

my $g = Data::Graph::Shared->new(undef, $N, $N * 3);

bench "add_node", $N, sub {
    $g->add_node($_) for 1..$N;
};

bench "add_edge (random)", $N * 2, sub {
    for (1..$N * 2) {
        $g->add_edge(int(rand($N)), int(rand($N)), int(rand(100)));
    }
};

bench "has_node", $N, sub {
    $g->has_node($_) for 0..$N-1;
};

bench "node_data", $N, sub {
    $g->node_data($_) for 0..$N-1;
};

bench "neighbors (first 1000)", 1000, sub {
    $g->neighbors($_) for 0..999;
};

bench "degree (first 1000)", 1000, sub {
    $g->degree($_) for 0..999;
};
