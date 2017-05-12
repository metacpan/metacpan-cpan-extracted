#-*-CPerl-*-

#########################
use strict;
use warnings;

use Test::More tests => 22;
use lib qw( lib ../lib ../../lib ); #Just in case we are testing it in-place

use Algorithm::Evolutionary qw(Fitness::ONEMAX Individual::BitString);

BEGIN {
  use_ok( "Algorithm::Evolutionary::Op::Eval::General" );
}

#########################

my $onemax = new Algorithm::Evolutionary::Fitness::ONEMAX;

my @pop;
my $number_of_bits = 20;
my $population_size = 20;
my $replacement_rate = 0.5;
for ( 1..$population_size ) {
  my $indi = new Algorithm::Evolutionary::Individual::BitString $number_of_bits ; #Creates random individual
  push( @pop, $indi );
}

my $e =  new Algorithm::Evolutionary::Op::Eval::General $onemax;

isa_ok( $e,  "Algorithm::Evolutionary::Op::Eval::General");

$e->apply( \@pop);

for my $p ( @pop ) {
  is( defined $p->Fitness(), 1, "Defined fitness");
}

=cut
