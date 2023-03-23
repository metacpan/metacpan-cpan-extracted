#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use Test2::Tools::Compare;

use Convert::Color::HSL;

use constant {
   NEAR_SQRT1d25_OVER_2 => Test2::Tools::Compare::float( sqrt(1.25)/2, tolerance => 1e-6 ),
   NEAR_1_OVER_2        => Test2::Tools::Compare::float( 1/2,          tolerance => 1e-6 ),
};

my $black = Convert::Color::HSL->new(   0, 1, 0 );
my $white = Convert::Color::HSL->new(   0, 1, 1 );
my $red   = Convert::Color::HSL->new(   0, 1, 0.5 );
my $green = Convert::Color::HSL->new( 120, 1, 0.5 );
my $cyan  = Convert::Color::HSL->new( 180, 1, 0.5 );
my $blue  = Convert::Color::HSL->new( 240, 1, 0.5 );

is( $black->dst_hsl( $black ), 0, 'black->dst_hsl black' );

is( $black->dst_hsl( $red   ), NEAR_SQRT1d25_OVER_2, 'black->dst_hsl red' );
is( $black->dst_hsl( $green ), NEAR_SQRT1d25_OVER_2, 'black->dst_hsl green' );
is( $black->dst_hsl( $blue  ), NEAR_SQRT1d25_OVER_2, 'black->dst_hsl blue' );

is( $black->dst_hsl( $white ), NEAR_1_OVER_2, 'black->dst_hsl white' );

is( $red->dst_hsl( $cyan ), 1, 'red->dst_hsl cyan' );

is( $black->dst_hsl_cheap( $black ), 0, 'black->dst_hsl_cheap black' );

is( $black->dst_hsl_cheap( $red   ), 1.25, 'black->dst_hsl_cheap red' );
is( $black->dst_hsl_cheap( $green ), 1.25, 'black->dst_hsl_cheap green' );
is( $black->dst_hsl_cheap( $blue  ), 1.25, 'black->dst_hsl_cheap blue' );

is( $black->dst_hsl_cheap( $white ), 1, 'black->dst_hsl_cheap white' );

is( $red->dst_hsl_cheap( $cyan ), 4, 'red->dst_hsl_cheap cyan' );

done_testing;
