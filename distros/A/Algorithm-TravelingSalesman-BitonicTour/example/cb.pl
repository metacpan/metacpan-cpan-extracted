#!perl

# usage: perl cb.pl

use strict;
use warnings;
use lib '../lib', 'lib';
use Algorithm::TravelingSalesman::BitonicTour;

my $b = Algorithm::TravelingSalesman::BitonicTour->new;

# Grid points from Cormen, Figure 15.9, p. 365.  Note that points can be added
# in any order; these just happen to be left-to-right.

$b->add_point(0,6);
$b->add_point(1,0);
$b->add_point(2,3);
$b->add_point(5,4);
$b->add_point(6,1);
$b->add_point(7,5);
$b->add_point(8,2);

my ($length, @tour) = $b->solve;

print "length of optimal bitonic tour: $length\n";
print "points in optimal bitonic tour:\n";
print "  (@$_)\n" for @tour;

