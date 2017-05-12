#-*-CPerl-*-

#########################
use strict;
use warnings;

use Test::More tests => 4;
use lib qw( lib ../lib ../../lib ); #Just in case we are testing it in-place

use Algorithm::Evolutionary qw(Fitness::ZDT1 Individual::BitString);

BEGIN {
  use_ok( "Algorithm::Evolutionary::Op::Easy_MO" );
}

#########################

my $number_of_bits = 10;
my $zdt1 = new Algorithm::Evolutionary::Fitness::ZDT1 $number_of_bits;

my @pop;

my $population_size = 100;
for ( 1..$population_size ) {
  my $indi = new Algorithm::Evolutionary::Individual::BitString 30*$number_of_bits ; #Creates random individual
  push( @pop, $indi );
}

my $e =  new Algorithm::Evolutionary::Op::Easy_MO $zdt1;

isa_ok( $e,  "Algorithm::Evolutionary::Op::Easy_MO");

$e->apply( \@pop);

my $best_fitness = $pop[0]->Fitness();

is ( $best_fitness == 1, 1, "First generation" );

$e->apply( \@pop);

is(  $pop[0]->Fitness() == 1, 1, "Improving fitness" );

=cut
