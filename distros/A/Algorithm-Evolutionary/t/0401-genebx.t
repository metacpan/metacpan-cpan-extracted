#-*-cperl-*-

use warnings;
use strict;

use lib qw( ../../lib ../lib lib ); #Just in case we are testing it in-place

use Test::More tests => 5;

BEGIN { 
  use_ok( 'Algorithm::Evolutionary::Op::Gene_Boundary_Crossover' );
};

use Algorithm::Evolutionary::Individual::BitString;

my $bits = 36;
my $size = 6;
my $indi = new Algorithm::Evolutionary::Individual::BitString $bits;
my $indi2 = new Algorithm::Evolutionary::Individual::BitString $bits;

my $gx = new Algorithm::Evolutionary::Op::Gene_Boundary_Crossover 2, $size;
isa_ok( $gx, 'Algorithm::Evolutionary::Op::Gene_Boundary_Crossover' );

isnt( $gx->apply($indi, $indi2), $indi, "Testing gene boundary crossover" );
isnt( $gx->apply($indi, $indi2), $indi2, "Testing gene boundary crossover 2" );

$gx = new Algorithm::Evolutionary::Op::Gene_Boundary_Crossover 1, $bits/2;
isnt( $gx->apply($indi, $indi2), $indi, "Testing gene boundary crossover 3" );

