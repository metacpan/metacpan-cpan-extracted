#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Convert::Color::RGB;
use Convert::Color::RGB8;

my $red = Convert::Color::RGB->new( 1, 0, 0 );
my $white = Convert::Color::RGB->new( 1, 1, 1 );
my $black = Convert::Color::RGB->new( 0, 0, 0 );

my $pink = $red->alpha_blend( $white );
isa_ok( $pink, "Convert::Color::RGB", 'red->alpha_blend constructs Convert::Color::RGB' );

is_deeply( [ $pink->rgb ], [ 1, 0.5, 0.5 ], 'alpha_blend rgb' );

is_deeply( [ $red->alpha_blend( $white, 0.25 )->rgb ], [ 1, 0.25, 0.25 ], 'alpha_blend(0.25) white' );
is_deeply( [ $red->alpha_blend( $white, 0.75 )->rgb ], [ 1, 0.75, 0.75 ], 'alpha_blend(0.75) white' );

is_deeply( [ $red->alpha_blend( $black, 0.25 )->rgb ], [ 0.75, 0, 0 ], 'alpha_blend(0.25) black' );

my $red8 = Convert::Color::RGB8->new( 255, 0, 0 );
my $white8 = Convert::Color::RGB8->new( 255, 255, 255 );
my $black8 = Convert::Color::RGB8->new( 0, 0, 0 );

my $pink8 = $red8->alpha_blend( $white8 );
isa_ok( $pink8, "Convert::Color::RGB8", 'red8->alpha_blend constructs Convert::Color::RGB8' );

is_deeply( [ $pink8->rgb8 ], [ 255, 128, 128 ], 'alpha_blend rgb' );

is_deeply( [ $red8->alpha_blend( $white8, 0.25 )->rgb8 ], [ 255, 64, 64 ], 'alpha_blend(0.25) white8' );
is_deeply( [ $red8->alpha_blend( $white8, 0.75 )->rgb8 ], [ 255, 191, 191 ], 'alpha_blend(0.75) white8' );

is_deeply( [ $red8->alpha_blend( $black8, 0.25 )->rgb8 ], [ 191, 0, 0 ], 'alpha_blend(0.25) black8' );

isa_ok( $red8->alpha8_blend( $white8 ), "Convert::Color::RGB8", 'red8->alpha8_blend constructs Convert::Color::RGB8' );

is_deeply( [ $red8->alpha8_blend( $white8, 64 )->rgb8 ], [ 255, 64, 64 ], 'alpha8_blend(64) white8' );
is_deeply( [ $red8->alpha8_blend( $white8, 191 )->rgb8 ], [ 255, 191, 191 ], 'alpha8_blend(191) white8' );

is_deeply( [ $red8->alpha8_blend( $black8, 64 )->rgb8 ], [ 191, 0, 0 ], 'alpha8_blend(64) black8' );

my $red16 = Convert::Color::RGB16->new( 0xffff, 0, 0 );
my $white16 = Convert::Color::RGB16->new( 0xffff, 0xffff, 0xffff );
my $black16 = Convert::Color::RGB16->new( 0, 0, 0 );

my $pink16 = $red16->alpha_blend( $white16 );
isa_ok( $pink16, "Convert::Color::RGB16", 'red16->alpha_blend constructs Convert::Color::RGB16' );

is_deeply( [ $pink16->rgb16 ], [ 0xffff, 0x8000, 0x8000 ], 'alpha_blend rgb' );

is_deeply( [ $red16->alpha_blend( $white16, 0.25 )->rgb16 ], [ 0xffff, 0x4000, 0x4000 ], 'alpha_blend(0.25) white16' );
is_deeply( [ $red16->alpha_blend( $white16, 0.75 )->rgb16 ], [ 0xffff, 0xbfff, 0xbfff ], 'alpha_blend(0.75) white16' );

is_deeply( [ $red16->alpha_blend( $black16, 0.25 )->rgb16 ], [ 0xbfff, 0, 0 ], 'alpha_blend(0.25) black16' );

isa_ok( $red16->alpha16_blend( $white16 ), "Convert::Color::RGB16", 'red16->alpha16_blend constructs Convert::Color::RGB16' );

is_deeply( [ $red16->alpha16_blend( $white16, 0x4000 )->rgb16 ], [ 0xffff, 0x4000, 0x4000 ], 'alpha16_blend(0x4000) white16' );
is_deeply( [ $red16->alpha16_blend( $white16, 0xbfff )->rgb16 ], [ 0xffff, 0xbfff, 0xbfff ], 'alpha16_blend(0xbfff) white16' );

is_deeply( [ $red16->alpha16_blend( $black16, 0x4000 )->rgb16 ], [ 0xbfff, 0, 0 ], 'alpha16_blend(0x4000) black16' );

done_testing;
