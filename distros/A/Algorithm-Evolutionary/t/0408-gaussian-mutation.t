#-*-cperl-*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use warnings;
use strict;

use lib qw( ../../lib ../lib lib ); #Just in case we are testing it in-place

use Test::More;

BEGIN { 
  use_ok( 'Algorithm::Evolutionary::Op::GaussianMutation' );
};

use Algorithm::Evolutionary::Individual::Vector;

my $number_of_components = 16;
my $indi = new Algorithm::Evolutionary::Individual::Vector $number_of_components;

my $center = 0;
my $sd = 0.5;
my $sm = new Algorithm::Evolutionary::Op::GaussianMutation $center, $sd;
isa_ok( $sm, 'Algorithm::Evolutionary::Op::GaussianMutation' );

my $result;
for ( 1..100 ) {
  $result = $sm->apply( $indi );
  for ( my $i = 0; $i < $indi->size(); $i ++ ) {
    isnt( $result->Atom($i), $indi->Atom($i), 
	$result->Atom($i)." differs from ". $indi->Atom($i));
    isnt( $result->Atom($i) > $indi->{'_rangeend'}, 1,  'Within upper bounds');
    isnt( $result->Atom($i) < $indi->{'_rangestart'}, 1,  'Within lower bounds');
  }
}

done_testing();
