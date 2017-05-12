#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Convert::Color::RGB;
use Convert::Color::RGB8;
use Convert::Color::RGB16;

my $red = Convert::Color::RGB->new( 1, 0, 0 );

is( $red->red,   1, 'red red' );
is( $red->green, 0, 'red green' );
is( $red->blue,  0, 'red blue' );

is_deeply( [ $red->rgb ], [ 1, 0, 0 ], 'red rgb' );
is_deeply( [ $red->as_rgb8->rgb8 ], [ 255, 0, 0 ], 'red rgb8' );
is_deeply( [ $red->as_rgb16->rgb16 ], [ 0xffff, 0, 0 ], 'red rgb16' );

is( $red->as_rgb8->hex, 'ff0000', 'red rgb8 hex' );
is( $red->as_rgb16->hex, 'ffff00000000', 'red rgb16 hex' );

my $green = Convert::Color::RGB->new( 0, 1, 0 );

is( $green->red,   0, 'green red' );
is( $green->green, 1, 'green green' );
is( $green->blue,  0, 'green blue' );

is_deeply( [ $green->rgb ], [ 0, 1, 0 ], 'green rgb' );
is_deeply( [ $green->as_rgb8->rgb8 ], [ 0, 255, 0 ], 'green rgb8' );
is_deeply( [ $green->as_rgb16->rgb16 ], [ 0, 0xffff, 0 ], 'green rgb16' );

is( $green->as_rgb8->hex, '00ff00', 'green rgb8_hex' );
is( $green->as_rgb16->hex, '0000ffff0000', 'green rgb16_hex' );

my $blue = Convert::Color::RGB->new( 0, 0, 1 );

is( $blue->red,   0, 'blue red' );
is( $blue->green, 0, 'blue green' );
is( $blue->blue,  1, 'blue blue' );

is_deeply( [ $blue->rgb ], [ 0, 0, 1 ], 'blue rgb' );
is_deeply( [ $blue->as_rgb8->rgb8 ], [ 0, 0, 255 ], 'blue rgb8' );
is_deeply( [ $blue->as_rgb16->rgb16 ], [ 0, 0, 0xffff ], 'blue rgb16' );

is( $blue->as_rgb8->hex, '0000ff', 'blue rgb8_hex' );
is( $blue->as_rgb16->hex, '00000000ffff', 'blue rgb16_hex' );

my $yellow = Convert::Color::RGB8->new( 'ffff00' );

is( $yellow->red,   255, 'yellow red' );
is( $yellow->green, 255, 'yellow green' );
is( $yellow->blue,    0, 'yellow blue' );

is_deeply( [ $yellow->rgb ], [ 1, 1, 0 ], 'yellow rgb' );
is_deeply( [ $yellow->as_rgb8->rgb8 ], [ 255, 255, 0 ], 'yellow rgb8' );
is_deeply( [ $yellow->as_rgb16->rgb16 ], [ 0xffff, 0xffff, 0 ], 'yellow rgb16' );

is( $yellow->as_rgb8->hex, 'ffff00', 'yellow rgb8_hex' );
is( $yellow->as_rgb16->hex, 'ffffffff0000', 'yellow rgb16_hex' );

my $cyan = Convert::Color::RGB16->new( '0000ffffffff' );

is( $cyan->red,        0, 'cyan red' );
is( $cyan->green, 0xffff, 'cyan green' );
is( $cyan->blue,  0xffff, 'cyan blue' );

is_deeply( [ $cyan->rgb ], [ 0, 1, 1 ], 'cyan rgb' );
is_deeply( [ $cyan->as_rgb8->rgb8 ], [ 0, 255, 255 ], 'cyan rgb8' );
is_deeply( [ $cyan->as_rgb16->rgb16 ], [ 0, 0xffff, 0xffff ], 'cyan rgb16' );

is( $cyan->as_rgb8->hex, '00ffff', 'cyan rgb8_hex' );
is( $cyan->as_rgb16->hex, '0000ffffffff', 'cyan rgb16_hex' );

my $grey = Convert::Color::RGB->new( '0.5,0.5,0.5' );

is( $grey->red,   0.5, 'grey red' );
is( $grey->green, 0.5, 'grey green' );
is( $grey->blue,  0.5, 'grey blue' );

is_deeply( [ $grey->rgb ], [ 0.5, 0.5, 0.5 ], 'grey rgb' );
is_deeply( [ $grey->as_rgb8->rgb8 ], [ 127, 127, 127 ], 'grey rgb8' );
is_deeply( [ $grey->as_rgb16->rgb16 ], [ 0x7fff, 0x7fff, 0x7fff ], 'grey rgb16' );

is( $grey->as_rgb8->hex, '7f7f7f', 'grey rgb8_hex' );
is( $grey->as_rgb16->hex, '7fff7fff7fff', 'grey rgb16_hex' );

my $grey_2 = $grey->as_rgb;
isa_ok( $grey_2, 'Convert::Color::RGB', '->rgb (identity) conversion' );

is( $grey_2->red,   0.5, 'grey_2 red' );
is( $grey_2->green, 0.5, 'grey_2 green' );
is( $grey_2->blue,  0.5, 'grey_2 blue' );

done_testing;
