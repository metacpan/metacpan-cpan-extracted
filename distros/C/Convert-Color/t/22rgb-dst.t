#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Number::Delta;

use Convert::Color::RGB;
use Convert::Color::RGB8;
use Convert::Color::RGB16;

my $black = Convert::Color::RGB->new( 0, 0, 0 );
my $white = Convert::Color::RGB->new( 1, 1, 1 );
my $red   = Convert::Color::RGB->new( 1, 0, 0 );
my $green = Convert::Color::RGB->new( 0, 1, 0 );
my $blue  = Convert::Color::RGB->new( 0, 0, 1 );

is( $black->dst_rgb( $black ), 0, 'black->dst_rgb black' );

delta_ok( $black->dst_rgb( $red   ), 1/sqrt(3), 'black->dst_rgb red' );
delta_ok( $black->dst_rgb( $green ), 1/sqrt(3), 'black->dst_rgb green' );
delta_ok( $black->dst_rgb( $blue  ), 1/sqrt(3), 'black->dst_rgb blue' );

is( $black->dst_rgb( $white ), 1, 'black->dst_rgb white' );

is( $black->dst_rgb_cheap( $black ), 0, 'black->dst_rgb_cheap black' );

is( $black->dst_rgb_cheap( $red   ), 1, 'black->dst_rgb_cheap red' );
is( $black->dst_rgb_cheap( $green ), 1, 'black->dst_rgb_cheap green' );
is( $black->dst_rgb_cheap( $blue  ), 1, 'black->dst_rgb_cheap blue' );

is( $black->dst_rgb_cheap( $white ), 3, 'black->dst_rgb_cheap white' );

my $black8 = Convert::Color::RGB8->new(   0,   0,   0 );
my $white8 = Convert::Color::RGB8->new( 255, 255, 255 );
my $red8   = Convert::Color::RGB8->new( 255,   0,   0 );
my $green8 = Convert::Color::RGB8->new(   0, 255,   0 );
my $blue8  = Convert::Color::RGB8->new(   0,   0, 255 );

is( $black8->dst_rgb8( $black8 ), 0, 'black8->dst_rgb8 black8' );
is( $black8->dst_rgb8( $black  ), 0, 'black8->dst_rgb8 black' );

delta_ok( $black8->dst_rgb8( $red8   ), 1/sqrt(3), 'black8->dst_rgb8 red8' );
delta_ok( $black8->dst_rgb8( $green8 ), 1/sqrt(3), 'black8->dst_rgb8 green8' );
delta_ok( $black8->dst_rgb8( $blue8  ), 1/sqrt(3), 'black8->dst_rgb8 blue8' );

is( $black8->dst_rgb8( $white8 ), 1, 'black8->dst_rgb8 white8' );
is( $black8->dst_rgb8( $white  ), 1, 'black8->dst_rgb8 white' );

is( $black8->dst_rgb8_cheap( $black8 ), 0, 'black8->dst_rgb8_cheap black8' );

is( $black8->dst_rgb8_cheap( $red8   ), 255*255, 'black8->dst_rgb8_cheap red8' );
is( $black8->dst_rgb8_cheap( $green8 ), 255*255, 'black8->dst_rgb8_cheap green8' );
is( $black8->dst_rgb8_cheap( $blue8  ), 255*255, 'black8->dst_rgb8_cheap blue8' );

is( $black8->dst_rgb8_cheap( $white8 ), 3*255*255, 'black8->dst_rgb8_cheap white8' );

my $black16 = Convert::Color::RGB16->new(      0,      0,      0 );
my $white16 = Convert::Color::RGB16->new( 0xffff, 0xffff, 0xffff );
my $red16   = Convert::Color::RGB16->new( 0xffff,      0,      0 );
my $green16 = Convert::Color::RGB16->new(      0, 0xffff,      0 );
my $blue16  = Convert::Color::RGB16->new(      0,      0, 0xffff );

is( $black16->dst_rgb16( $black16 ), 0, 'black16->dst_rgb16 black16' );
is( $black16->dst_rgb16( $black   ), 0, 'black16->dst_rgb16 black' );

is( $black16->dst_rgb16( $red16   ), 1/sqrt(3), 'black16->dst_rgb16 red16' );
is( $black16->dst_rgb16( $green16 ), 1/sqrt(3), 'black16->dst_rgb16 green16' );
is( $black16->dst_rgb16( $blue16  ), 1/sqrt(3), 'black16->dst_rgb16 blue16' );

is( $black16->dst_rgb16( $white16 ), 1, 'black16->dst_rgb16 white16' );
is( $black16->dst_rgb16( $white   ), 1, 'black16->dst_rgb16 white' );

is( $black16->dst_rgb16_cheap( $black16 ), 0, 'black16->dst_rgb16_cheap black16' );

is( $black16->dst_rgb16_cheap( $red16   ), 0xffff*0xffff, 'black16->dst_rgb16_cheap red16' );
is( $black16->dst_rgb16_cheap( $green16 ), 0xffff*0xffff, 'black16->dst_rgb16_cheap green16' );
is( $black16->dst_rgb16_cheap( $blue16  ), 0xffff*0xffff, 'black16->dst_rgb16_cheap blue16' );

is( $black16->dst_rgb16_cheap( $white16 ), 3*0xffff*0xffff, 'black16->dst_rgb16_cheap white16' );

done_testing;
