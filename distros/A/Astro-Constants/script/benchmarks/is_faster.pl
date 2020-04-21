#!/usr/bin/perl -w
#
# benchmark - tries to determine which is faster
#	short constants or long names

use strict;
use Benchmark qw(:all);
use lib '../../lib';
use Astro::Constants::MKS qw/:long :short/;

use constant COULOMB => (1 / PI / PERMITIV_FREE_SPACE / 4);

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

print "Perl version: $]\tOS: $^O\n\n";

print "Sanity checking calculations\n";
print "Eps:  Fe = ", CHARGE_ELEMENTARY**2 / RADIUS_BOHR / PI / PERMITIV_FREE_SPACE / 4, "\n";
print "Cou:  Fe = ", COULOMB * CHARGE_ELEMENTARY**2 / RADIUS_BOHR, "\n";
print "\n";


my $r = timethese( $count, {
	Epsilon	=> sub {
		$force = CHARGE_ELEMENTARY**2 / RADIUS_BOHR / PI / PERMITIV_FREE_SPACE / 4;
		},
	Coulomb	=> sub {
		$force = COULOMB * CHARGE_ELEMENTARY**2 / RADIUS_BOHR;
		},
} );

cmpthese $r;

