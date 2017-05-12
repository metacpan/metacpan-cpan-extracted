#-*-cperl-*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use warnings;
use strict;

use lib qw( ../../lib ../lib lib ); #Just in case we are testing it in-place

use Test::More;

BEGIN { 
  use_ok( 'Algorithm::Evolutionary::Op::Permutation' );
};

use Algorithm::Evolutionary::Individual::String;

my $number_of_chars = 8;
my $sm = new Algorithm::Evolutionary::Op::Permutation;

isa_ok( $sm, 'Algorithm::Evolutionary::Op::Permutation' );

my @strings = qw( ABCD EFGHIJ BCDAEFGH ACEF ABCDEF FEDCBA ABCDEFGHIJKLM );
my  $indi;
my  $result;
for my $s (@strings ) {
  $indi = Algorithm::Evolutionary::Individual::String->fromString( $s );

  for ( 1..100 ) {
    $result = $sm->apply( $indi );
    isnt( $result->{'_str'}, $indi->{'_str'}, 
	  $result->{'_str'}." differs from ". $indi->{'_str'});
    
  }
}

$indi = Algorithm::Evolutionary::Individual::String->fromString( "AAAA" );
$result = $sm->apply( $indi );
is( $result->{'_str'}, $indi->{'_str'},  "What else?");

my @chars = 'A'..'Z';
$indi = Algorithm::Evolutionary::Individual::String->fromString( join('',@chars) );

for ( 1..100 ) {
  $result =  $sm->apply( $indi );
  isnt( $result->{'_str'}, $indi->{'_str'}, 
	$result->{'_str'}." differs from ". $indi->{'_str'});

}
done_testing();
