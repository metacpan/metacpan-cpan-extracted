#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Convert::Color::mIRC;
use Convert::Color::RGB;

my $black = Convert::Color::mIRC->new( 1 );

is( $black->red,   0, 'black red' );
is( $black->green, 0, 'black green' );
is( $black->blue,  0, 'black blue' );

is( $black->index, 1, 'black index' );

my $green = Convert::Color::mIRC->new( 3 );

is(     $green->red,           0, 'green red' );
cmp_ok( $green->green, '>=', 100, 'green green' ); # Try not to be exact in case the palette is changed
is(     $green->blue,          0, 'green blue' );

is( $green->index, 3, 'green index' );

my $red = Convert::Color::RGB->new( 1.0, 0.0, 0.0 )->as_mirc;

cmp_ok( $red->red,   '>=', 200, 'red red' );
is(     $red->green,         0, 'red green' );
is(     $red->blue,          0, 'red blue' );

is( $red->index, 4, 'red index' );

done_testing;
