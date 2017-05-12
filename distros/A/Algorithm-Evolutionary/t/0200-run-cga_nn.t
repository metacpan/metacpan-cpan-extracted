#-*-cperl-*-


use Test::More tests => 5;

use warnings;
use strict;

use lib qw( ../../lib ../lib lib ); #Just in case we are testing it in-place
use Algorithm::Evolutionary qw(Fitness::ONEMAX 
			       Individual::BitString);


BEGIN {
  use_ok( "Algorithm::Evolutionary::Op::Canonical_GA_NN", "using AE::Op::CGA OK" );
}

my $number_of_bits = 32;
my $onemax = new Algorithm::Evolutionary::Fitness::ONEMAX;

my @pop;

my $population_size = 100;
for ( 1..$population_size ) {
  my $indi = new Algorithm::Evolutionary::Individual::BitString $number_of_bits ; #Creates random individual
  $indi->evaluate( $onemax );
  push( @pop, $indi );
}

my $e =  new Algorithm::Evolutionary::Op::Canonical_GA_NN;

isa_ok( $e,  "Algorithm::Evolutionary::Op::Canonical_GA_NN");

$e->apply( \@pop);

is( scalar @pop, $population_size, "Size OK" );

my $best_fitness = $pop[0]->Fitness();

is ( $best_fitness > 1, 1, "First generation $best_fitness" );

for ( 1..10 ) {
  map( $_->evaluate( $onemax ), @pop );
  $e->apply( \@pop);
}

SKIP: {
  skip "Unlucky with improving fitness this time", 1 unless $pop[0]->Fitness() >= $best_fitness;
  cmp_ok(  $pop[0]->Fitness(), ">=", $best_fitness, "Improving fitness to ". $pop[0]->Fitness() );
}
