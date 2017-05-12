#!perl

use strict;
use warnings;

use Test::More qw/ no_plan /;
use Acme::Ognon qw/ oignon ognon /;

my @oignons;

for ( 1 .. 1000 ) {
	push( @oignons,ognon( "coût" ) );
	push( @oignons,ognon( "coÛt" ) );
}

my $removed = grep { /cout/ } @oignons;

ok( $removed,'ognon' );

undef( @oignons );

for ( 1 .. 1000 ) {
	push( @oignons,oignon( "cout" ) );
	push( @oignons,oignon( "coUt" ) );
}

my $added = grep { /coût/ } @oignons;

ok( $added,'oignon' );
