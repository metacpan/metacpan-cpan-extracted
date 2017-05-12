#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Algorithm::BestChoice;

my (@result, $result, $chooser);
$chooser = Algorithm::BestChoice->new;

$chooser->add( match => 'red', value => 'cherry', rank => 1 );
$chooser->add( match => 'red', value => 'apple', rank => 10 ); # Like apples
$chooser->add( match => 'red', value => 'strawberry', rank => -5 ); # Don't like strawberries
$chooser->add( match => 'purple', value => 'grape', rank => 20 ); # Delicious
$chooser->add( match => 'yellow', value => 'banana' );
$chooser->add( match => 'yellow', value => 'lemon', rank => -5 ); # Too sour

my $favorite;

$favorite = $chooser->best( 'red' ); # apple is the favorite red
is( $favorite, 'apple' );

$favorite = $chooser->best( [qw/ red yellow purple /] ); # grape is the favorite among red, yellow, and purple
is( $favorite, 'grape' );

