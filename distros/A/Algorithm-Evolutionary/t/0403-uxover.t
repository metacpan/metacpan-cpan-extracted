#-*-cperl-*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use warnings;
use strict;

use lib qw( ../../lib ../lib lib ); #Just in case we are testing it in-place

use Test::More tests => 6;

BEGIN { 
  use_ok( 'Algorithm::Evolutionary::Op::Uniform_Crossover' );
};

use Algorithm::Evolutionary::Individual::BitString;

my $number_of_bits = 128;
my $indi = new Algorithm::Evolutionary::Individual::BitString $number_of_bits;
my $other_indi = new Algorithm::Evolutionary::Individual::BitString $number_of_bits;

my $ux = new Algorithm::Evolutionary::Op::Uniform_Crossover 0.5;
isa_ok( $ux, 'Algorithm::Evolutionary::Op::Uniform_Crossover' );

my $result = $ux->apply( $indi, $other_indi);
isnt( $result, $indi, "Differs from 1");
isnt( $result, $other_indi, "Differs from 2");

$ux = new Algorithm::Evolutionary::Op::Uniform_Crossover 0.1;
$result = $ux->apply( $indi, $other_indi);
isnt( $result, $indi, "Differs from 1");
isnt( $result, $other_indi, "Differs from 2");
