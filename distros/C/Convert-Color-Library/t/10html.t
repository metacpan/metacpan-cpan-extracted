#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Convert::Color::HTML;
use Convert::Color;

my $red = Convert::Color::HTML->new( 'red' );

is( $red->red,   255, 'red red' );
is( $red->green,   0, 'red green' );
is( $red->blue,    0, 'red blue' );

is( $red->name, "red",  'red name' );
is( $red->dict, "html", 'red dict' );

my $green = Convert::Color::HTML->new( '#00FF00' );

is( $green->red,     0, 'green red' );
is( $green->green, 255, 'green green' );
is( $green->blue,    0, 'green blue' );

is( $green->name, '#00FF00', 'green name from hex' );

my $blue = Convert::Color->new( 'html:blue' );

is( $blue->name, "blue", 'blue name' );
is( $blue->dict, "html", 'blue dict' );

# Conversions
{
   my $white = Convert::Color->new( 'rgb:1,1,1' )->as_html;

   is( $white->red,   255, 'white red' );
   is( $white->green, 255, 'white green' );
   is( $white->blue,  255, 'white blue' );

   is( $white->name, "white", 'white name' );

   my $grey92 = Convert::Color->new( 'rgb:0.92,0.92,0.92' )->as_html;

   # This shouldn't be exact, so we'll see a hex triplet
   is( $grey92->name, "#EAEAEA", 'grey92 name' );
}

done_testing;
