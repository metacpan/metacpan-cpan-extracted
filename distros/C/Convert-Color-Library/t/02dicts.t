#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Convert::Color::Library;

my $green = Convert::Color::Library->new( 'x11/green' );

is( $green->red,     0, 'x11/green red' );
is( $green->green, 255, 'x11/green green' );
is( $green->blue,    0, 'x11/green blue' );

is( $green->dict, "x11", 'x11/green dict' );

$green = Convert::Color::Library->new( 'svg/green' );

is( $green->red,     0, 'svg/green red' );
is( $green->green, 128, 'svg/green green' );
is( $green->blue,    0, 'svg/green blue' );

is( $green->dict, "svg", 'svg/green dict' );

done_testing;
