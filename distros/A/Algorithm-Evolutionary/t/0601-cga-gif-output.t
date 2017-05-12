#-*-CPerl-*-

#########################
use strict;
use warnings;

use Test::More;
use lib qw( lib ../lib ../../lib ); #Just in case we are testing it in-place

use Algorithm::Evolutionary qw(Fitness::ONEMAX 
			       Individual::BitString
			       Op::Easy);

BEGIN {
  use_ok( "Algorithm::Evolutionary::Op::Animated_GIF_Output" );
}

#########################

SKIP: {

my $number_of_bits = 32;
my $pixels_per_bit = 3;
my $population_size = 100;
my $gif_output;
eval { 
  $gif_output = new Algorithm::Evolutionary::Op::Animated_GIF_Output 
    { length => $number_of_bits, 
	pixels_per_bit => $pixels_per_bit,
	  number_of_strings => $population_size };
};
skip "Incorrect version of the upstream library present", 3 if $@;
my $om = new Algorithm::Evolutionary::Fitness::ONEMAX $number_of_bits;

my @pop;

for ( 1..$population_size ) {
  my $indi = new Algorithm::Evolutionary::Individual::BitString 30*$number_of_bits ; #Creates random individual
  push( @pop, $indi );
}

my $e =  new Algorithm::Evolutionary::Op::Easy $om;
	
isa_ok( $gif_output, 'Algorithm::Evolutionary::Op::Animated_GIF_Output');

for ( 1..40 ) {
  $e->apply( \@pop);
  $gif_output->apply( \@pop );
}
$gif_output->terminate();
is( $gif_output->output() ne '', 1, "Output OK" );

}

done_testing;
