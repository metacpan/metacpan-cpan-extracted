#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;

use Algorithm::PageRank::XS;

my $pr = Algorithm::PageRank::XS->new();


# Run with the following graph.
$pr->graph([
    qw(
	       0 1
	       0 2
	       1 2
	       
	       3 4
	       3 5
	       3 6
	       4 3
	       4 6
	       5 3
	       5 6
	       6 4
	       6 3
	       6 5
	       )]);

my $x = $pr->result();

# We truncate digits here to prevent small floating point errors
while (my ($key, $value) = each(%{$x})) {
    $x->{$key} = sprintf("%0.5f", $value);
}

# Compare it to the answer.
is_deeply($x, {
          '6' => '0.28078',
          '4' => '0.21922',
          '1' => '0.00000',
          '3' => '0.28078',
          '0' => '0.00000',
          '2' => '0.00000',
          '5' => '0.21922'
        }, "Ran PageRank on simple graph");

