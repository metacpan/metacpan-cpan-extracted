#-*-CPerl-*-

#########################
use strict;
use warnings;

use Test::More tests => 4;
use lib qw( lib ../lib ../../lib ); #Just in case we are testing it in-place

use Algorithm::Evolutionary qw(Op::EDA_step Individual::BitString Fitness::Royal_Road);

BEGIN {
  use_ok( "Algorithm::Evolutionary::Op::EDA_step" );
}

#########################

my $number_of_bits = 64;
my $rr = new Algorithm::Evolutionary::Fitness::Royal_Road 4; #Block size = 4

my @pop;

my $population_size = 100;
my $replacement_rate = 0.5;
for ( 1..$population_size ) {
  my $indi = new Algorithm::Evolutionary::Individual::BitString $number_of_bits ; #Creates random individual
  push( @pop, $indi );
}

my $e =  new Algorithm::Evolutionary::Op::EDA_step $rr, $replacement_rate, $population_size;

isa_ok( $e,  "Algorithm::Evolutionary::Op::EDA_step");

$e->apply( \@pop);

my $best_fitness = $pop[0]->Fitness();

cmp_ok( $best_fitness, ">", 1, "First generation $best_fitness" );

$e->apply( \@pop);

cmp_ok(  $pop[0]->Fitness(), ">=", $best_fitness, "Improving fitness ".  $pop[0]->Fitness() );

=cut
