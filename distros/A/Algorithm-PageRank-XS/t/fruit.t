#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;
use Algorithm::PageRank::XS;
use FindBin;

my $pr = Algorithm::PageRank::XS->new();

open(FRUIT, $FindBin::Bin . "/fruitarcs.dat");

while (<FRUIT>) {
    chomp;
    my ($from, $to) = split(/\s+=>\s+/o, $_, 2);
    $pr->add_arc($from, $to);
}

my @results = ();

my %results = %{$pr->result()};
foreach my $key (sort keys %results) {
    push(@results, sprintf("%s,%0.4f", $key, $results{$key}));
}

my $result_data = join("\n", @results);

my $best_results = `cat $FindBin::Bin/fruitarcs.ranks`;

is($result_data."\n", $best_results, "Fruit arcs");

