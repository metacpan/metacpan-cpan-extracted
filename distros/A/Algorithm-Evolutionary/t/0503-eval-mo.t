#-*-CPerl-*-

#########################
use strict;
use warnings;

use Test::More tests => 102;
use lib qw( lib ../lib ../../lib ); #Just in case we are testing it in-place

use Algorithm::Evolutionary qw(Fitness::ZDT1 Individual::BitString);

BEGIN {
  use_ok( "Algorithm::Evolutionary::Op::Eval::MO_Rank" );
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

my $e =  new Algorithm::Evolutionary::Op::Eval::MO_Rank $zdt1;

isa_ok( $e,  "Algorithm::Evolutionary::Op::Eval::MO_Rank");

$e->apply( \@pop);

for my $p ( @pop ) {
  is( defined $p->Fitness(), 1, "Defined fitness");
}

=cut
