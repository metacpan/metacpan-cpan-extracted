#!/usr/bin/perl -w
#
# benchmark - tries to determine which is faster
#	short constants or long names

use strict;
use Benchmark qw(:all);
use lib '../../lib';
use Astro::Constants::MKS qw/:long :short/;


my $count = shift // -10;
my ($force, );

my $GRAV = 6.67408e-11;
my $MSOL = 1.9884e30;
my $MEAR = 5.9722e24;
my $AU   = 149_597_870_700;
my $CHARGE = 1.6021766208e-19;
my $BOHR = 5.2917721067e-11;
my $PI = atan2(1,1) * 4;
my $EPSILON = 8.854187817e-12;

print "Sanity checking calculations\n";
print "Short: Fg = ", $A_G * $A_msun * $A_mearth / $A_AU**2, "\n";
print "Long:  Fg = ", GRAVITATIONAL * MASS_SOLAR * MASS_EARTH / ASTRONOMICAL_UNIT**2, "\n";
print "Vars:  Fg = ", $GRAV * $MSOL * $MEAR / $AU**2, "\n";
print "Short: Fe = ", $A_e**2 / $A_a0 / $A_pi / $A_eps0 / 4, "\n";
print "Long:  Fe = ", CHARGE_ELEMENTARY**2 / RADIUS_BOHR / PI / PERMITIV_FREE_SPACE / 4, "\n";
print "Vars:  Fe = ", $CHARGE**2 / $BOHR / $PI / $EPSILON / 4, "\n";
print "\n";


my $r = timethese( $count, {
	bShortnames	=> sub {
		$force = $A_G * $A_msun * $A_mearth / $A_AU**2;
		$force = $A_me**2 / $A_a0 / $A_pi / $A_eps0 / 4;
		},
	cLongnames	=> sub {
		$force = GRAVITATIONAL * MASS_SOLAR * MASS_EARTH / ASTRONOMICAL_UNIT**2;
		$force = MASS_ELECTRON**2 / RADIUS_BOHR / PI / PERMITIV_FREE_SPACE / 4;
		},
	aVariables	=> sub {
		$force = $GRAV * $MSOL * $MEAR / $AU**2;
		$force = $CHARGE**2 / $BOHR / $PI / $EPSILON / 4;
		},
} );

cmpthese $r;

