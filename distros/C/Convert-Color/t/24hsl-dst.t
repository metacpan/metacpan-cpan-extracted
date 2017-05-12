#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Number::Delta;

use Convert::Color::HSL;

my $black = Convert::Color::HSL->new(   0, 1, 0 );
my $white = Convert::Color::HSL->new(   0, 1, 1 );
my $red   = Convert::Color::HSL->new(   0, 1, 0.5 );
my $green = Convert::Color::HSL->new( 120, 1, 0.5 );
my $cyan  = Convert::Color::HSL->new( 180, 1, 0.5 );
my $blue  = Convert::Color::HSL->new( 240, 1, 0.5 );

is( $black->dst_hsl( $black ), 0, 'black->dst_hsl black' );

delta_ok( $black->dst_hsl( $red   ), sqrt(1.25/4), 'black->dst_hsl red' );
delta_ok( $black->dst_hsl( $green ), sqrt(1.25/4), 'black->dst_hsl green' );
delta_ok( $black->dst_hsl( $blue  ), sqrt(1.25/4), 'black->dst_hsl blue' );

delta_ok( $black->dst_hsl( $white ), 0.5, 'black->dst_hsl white' );

is( $red->dst_hsl( $cyan ), 1, 'red->dst_hsl cyan' );

is( $black->dst_hsl_cheap( $black ), 0, 'black->dst_hsl_cheap black' );

is( $black->dst_hsl_cheap( $red   ), 1.25, 'black->dst_hsl_cheap red' );
is( $black->dst_hsl_cheap( $green ), 1.25, 'black->dst_hsl_cheap green' );
is( $black->dst_hsl_cheap( $blue  ), 1.25, 'black->dst_hsl_cheap blue' );

is( $black->dst_hsl_cheap( $white ), 1, 'black->dst_hsl_cheap white' );

is( $red->dst_hsl_cheap( $cyan ), 4, 'red->dst_hsl_cheap cyan' );

done_testing;
