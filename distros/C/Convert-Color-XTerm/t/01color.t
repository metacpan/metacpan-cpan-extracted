#!/usr/bin/perl

use v5.14;
use warnings;

use Convert::Color::XTerm;
use Convert::Color::RGB;

use Test::More;

my $black = Convert::Color::XTerm->new( 0 );

is( $black->red,   0, 'black red' );
is( $black->green, 0, 'black green' );
is( $black->blue,  0, 'black blue' );

is( $black->index, 0, 'black index' );

my $green = Convert::Color::XTerm->new( 2 );

is( $green->red,     0, 'green red' );
is( $green->green, 205, 'green green' );
is( $green->blue,    0, 'green blue' );

is( $green->index, 2, 'green index' );

my $white = Convert::Color::RGB->new( 1.0, 1.0, 1.0 )->as_xterm;

is( $white->index, 15, 'white index' );

# grey() specifications
{
   is( Convert::Color::XTerm->new( "grey(15)" )->index, 247, 'grey(15) index' );

   is( Convert::Color::XTerm->new( "grey(80%)" )->index, 250, 'grey(80) index' );
}

# rgb() specification
{
   is( Convert::Color::XTerm->new( "rgb(1,2,3)" )->index, 67, 'rgb(1,2,3) index' );
   is( Convert::Color::XTerm->new( "rgb(30%,60%,90%)" )->index, 74, 'rgb(1,2,3) index' );
}

done_testing;
