#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use Test2::Tools::Compare;

use Convert::Color::HSV;

use constant {
   NEAR_1_OVER_SQRT2 => Test2::Tools::Compare::float( 1/sqrt(2), tolerance => 1e-6 ),
   NEAR_1_OVER_2     => Test2::Tools::Compare::float( 1/2,       tolerance => 1e-6 ),
};

my $black = Convert::Color::HSV->new(   0, 1, 0 );
my $white = Convert::Color::HSV->new(   0, 0, 1 );
my $red   = Convert::Color::HSV->new(   0, 1, 1 );
my $green = Convert::Color::HSV->new( 120, 1, 1 );
my $cyan  = Convert::Color::HSV->new( 180, 1, 1 );
my $blue  = Convert::Color::HSV->new( 240, 1, 1 );

is( $black->dst_hsv( $black ), 0, 'black->dst_hsv black' );

is( $black->dst_hsv( $red   ), NEAR_1_OVER_SQRT2, 'black->dst_hsv red' );
is( $black->dst_hsv( $green ), NEAR_1_OVER_SQRT2, 'black->dst_hsv green' );
is( $black->dst_hsv( $blue  ), NEAR_1_OVER_SQRT2, 'black->dst_hsv blue' );

is( $black->dst_hsv( $white ), NEAR_1_OVER_2, 'black->dst_hsv white' );

is( $red->dst_hsv( $cyan ), 1, 'red->dst_hsv cyan' );

is( $black->dst_hsv_cheap( $black ), 0, 'black->dst_hsv_cheap black' );

is( $black->dst_hsv_cheap( $red   ), 2, 'black->dst_hsv_cheap red' );
is( $black->dst_hsv_cheap( $green ), 2, 'black->dst_hsv_cheap green' );
is( $black->dst_hsv_cheap( $blue  ), 2, 'black->dst_hsv_cheap blue' );

is( $black->dst_hsv_cheap( $white ), 1, 'black->dst_hsv_cheap white' );

is( $red->dst_hsv_cheap( $cyan ), 4, 'red->dst_hsv_cheap cyan' );

done_testing;
