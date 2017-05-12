#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Convert::Color::HSV;

my $red = Convert::Color::HSV->new( 0, 1, 1 );

is( $red->hue,          0, 'red hue' );
is( $red->saturation,   1, 'red saturation' );
is( $red->value,        1, 'red value' );

is( $red->chroma,       1, 'red chroma' );

is_deeply( [ $red->hsv ], [ 0, 1, 1 ], 'red hsv' );

my $green = Convert::Color::HSV->new( 120, 1, 1 );

is( $green->hue,        120, 'green hue' );
is( $green->saturation,   1, 'green saturation' );
is( $green->value,        1, 'green value' );

is( $green->chroma,       1, 'green chroma' );

is_deeply( [ $green->hsv ], [ 120, 1, 1 ], 'green hsv' );

my $blue = Convert::Color::HSV->new( 240, 1, 1 );

is( $blue->hue,        240, 'blue hue' );
is( $blue->saturation,   1, 'blue saturation' );
is( $blue->value,        1, 'blue value' );

is( $blue->chroma,       1, 'blue chroma' );

is_deeply( [ $blue->hsv ], [ 240, 1, 1 ], 'blue hsv' );

my $yellow = Convert::Color::HSV->new( '60,1,1' );

is( $yellow->hue,         60, 'yellow hue' );
is( $yellow->saturation,   1, 'yellow saturation' );
is( $yellow->value,        1, 'yellow value' );

is( $yellow->chroma,       1, 'yellow chroma' );

is_deeply( [ $yellow->hsv ], [ 60, 1, 1 ], 'yellow hsv' );

# "black" is anything at value 0
my $black = Convert::Color::HSV->new( '0,1,0' );

is( $black->saturation,   1, 'black saturation' );
is( $black->value,        0, 'black value' );

is( $black->chroma,       0, 'black chroma' );

my $bluegrey = Convert::Color::HSV->new( '240,1,0.5' );

is( $bluegrey->hue,        240, 'bluegrey hue' );
is( $bluegrey->saturation,   1, 'bluegrey saturation' );
is( $bluegrey->value,      0.5, 'bluegrey value' );

is( $bluegrey->chroma,     0.5, 'bluegrey chroma' );

done_testing;
