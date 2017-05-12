#!perl
use strict;
use warnings;

use Test::More tests => 3;
use Color::Scheme;

use t::lib::ColorTest;

my $scheme = Color::Scheme->new;

eval {
    $scheme->from_hex('e60003');
    $scheme->from_hue(360);
};
is $@, '', 'no errors';

my @set1 = $scheme->colors;
$scheme->from_hue(0);
my @set2 = $scheme->colors;
$scheme->from_hue(-360);
my @set3 = $scheme->colors;

color_test( \@set1, \@set2, '360 deg == 0 deg' );
color_test( \@set1, \@set3, '360 deg == -360 deg' );

