#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Convert::Color::Library;

my $red = Convert::Color::Library->new( 'red' );

is( $red->red,   255, 'red red' );
is( $red->green,   0, 'red green' );
is( $red->blue,    0, 'red blue' );

is( $red->name, "red", 'red name' );

# Color::Library would try to use the SVG dictionary first, which has this
# at 008000
my $green = Convert::Color->new( 'lib:green' );

is( $green->red,     0, 'green red' );
is( $green->green, 128, 'green green' );
is( $green->blue,    0, 'green blue' );

is( $green->name, "green", 'green name' );

done_testing;
