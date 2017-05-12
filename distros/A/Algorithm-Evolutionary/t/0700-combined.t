#-*-cperl-*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use warnings;
use strict;

use lib qw( ../../lib ../lib lib ); #Just in case we are testing it in-place

use Test::More tests => 102;

BEGIN { 
  use_ok( 'Algorithm::Evolutionary::Op::Combined' );
};

use Algorithm::Evolutionary qw( Individual::String 
				Op::String_Mutation Op::Permutation );

my @chars = 'A'..'Z';
my $indi = Algorithm::Evolutionary::Individual::String->fromString( join('',@chars) );

my $sm = new Algorithm::Evolutionary::Op::String_Mutation;
my $pm = new Algorithm::Evolutionary::Op::Permutation;

my $c =  new Algorithm::Evolutionary::Op::Combined [ $sm, $pm ];
isa_ok( $c, 'Algorithm::Evolutionary::Op::Combined' );

my $result;
for ( 1..100 ) {
  $result =  $c->apply( $indi );
  isnt( $result->{'_str'}, $indi->{'_str'}, 
	$result->{'_str'}." differs from ". $indi->{'_str'});

}

