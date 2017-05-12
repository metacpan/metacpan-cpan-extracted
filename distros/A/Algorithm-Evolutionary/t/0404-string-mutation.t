#-*-cperl-*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use warnings;
use strict;

use lib qw( ../../lib ../lib lib ); #Just in case we are testing it in-place

use Test::More tests => 303;

BEGIN { 
  use_ok( 'Algorithm::Evolutionary::Op::String_Mutation' );
};

use Algorithm::Evolutionary::Individual::String;

my $number_of_chars = 32;
my $indi = new Algorithm::Evolutionary::Individual::String [ qw( A B C D E F) ],
  $number_of_chars;

my $sm = new Algorithm::Evolutionary::Op::String_Mutation;
isa_ok( $sm, 'Algorithm::Evolutionary::Op::String_Mutation' );

my $result;
for ( 1..100 ) {
  $result = $sm->apply( $indi );
  isnt( $result->{'_str'}, $indi->{'_str'}, 
	$result->{'_str'}." differs from ". $indi->{'_str'});

}

$sm = new Algorithm::Evolutionary::Op::String_Mutation $number_of_chars / 4;
isa_ok( $sm, 'Algorithm::Evolutionary::Op::String_Mutation' );

for ( 1..100 ) {
  $result = $sm->apply( $indi );
  isnt( $result->{'_str'}, $indi->{'_str'}, 
	$result->{'_str'}." differs from ". $indi->{'_str'});

}

$indi->{'_str'} = 'BBBB';
$sm = new Algorithm::Evolutionary::Op::String_Mutation;
for ( 1..100 ) {
  $result = $sm->apply( $indi );
  isnt( $result->{'_str'}, $indi->{'_str'}, 
	$result->{'_str'}." differs from ". $indi->{'_str'});

}
