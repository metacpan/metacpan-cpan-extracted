#-*-cperl-*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use warnings;
use strict;

use lib qw( ../../lib ../lib lib ); #Just in case we are testing it in-place

use Test::More tests => 102;

BEGIN { 
  use_ok( 'Algorithm::Evolutionary::Op::Novelty_Mutation' );
};

use Algorithm::Evolutionary::Fitness::MMDP;
use Algorithm::Evolutionary::Individual::BitString;

my $mmdp = new  Algorithm::Evolutionary::Fitness::MMDP;
my $bits = 36;
my $units = 100;
my @population;
my $i;
for ( $i = 0; $i < $units; $i++ ) {
  my $indi = new Algorithm::Evolutionary::Individual::BitString $bits;
  $indi->evaluate( $mmdp );
  push @population, $indi;
}

my $nm = new Algorithm::Evolutionary::Op::Novelty_Mutation $mmdp->{'_cache'};
isa_ok( $nm, 'Algorithm::Evolutionary::Op::Novelty_Mutation' );

for ( $i = 0; $i < $units; $i++ ) {
  isnt( $nm->apply($population[$i]), $population[$i], "Testing individual $i" );
}
