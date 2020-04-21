#!/usr/bin/perl -w
#
# benchmark - tries to determine which is faster
#	short constants or long names

use strict;
use Benchmark qw(:all);
use lib '../../lib';
use Astro::Constants::MKS qw/:long :short/;

use Scalar::Constant
	SC_GRAV => 6.67408e-11,
	SC_MSOL => 1.9884e30,
	SC_MEAR	=> 5.9722e24,
	SC_AU   => 149_597_870_700;

use Const::Fast;

const my $CF_GRAV => 6.67408e-11;
const my $CF_MSOL => 1.9884e30;
const my $CF_MEAR => 5.9722e24;
const my $CF_AU   => 149_597_870_700;

my $count = shift // -10;
my ($force, );

print "Sanity checking calculations\n";
print "Short: Fg = ", $A_G * $A_msun * $A_mearth / $A_AU**2, "\n";
print "Long:  Fg = ", GRAVITATIONAL * MASS_SOLAR * MASS_EARTH / ASTRONOMICAL_UNIT**2, "\n";
print "ScalarConstant: Fg = ", $SC_GRAV * $SC_MSOL * $SC_MEAR / $SC_AU**2, "\n";
print "ConstFast:      Fg = ", $CF_GRAV * $CF_MSOL * $CF_MEAR / $CF_AU**2, "\n";
print "\n";


my $r = timethese( $count, {
	Shortnames	=> sub {
		$force = $A_G * $A_msun * $A_mearth / $A_AU**2;
		},
	Longnames	=> sub {
		$force = GRAVITATIONAL * MASS_SOLAR * MASS_EARTH / ASTRONOMICAL_UNIT**2;
		},
	ScalarConstant	=> sub {
		$force = $SC_GRAV * $SC_MSOL * $SC_MEAR / $SC_AU**2;
		},
	ConstFast	=> sub {
		$force = $CF_GRAV * $CF_MSOL * $CF_MEAR / $CF_AU**2;
		},
} );

cmpthese $r;

