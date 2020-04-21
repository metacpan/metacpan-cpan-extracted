#!/usr/bin/perl -w
#

use strict;
use lib '../../lib';
use Astro::Constants::MKS qw/:long/;


my $count = shift || 100;
my ($force, );

print "Sanity checking calculations\n";
print "Long:  Fg = ", GRAVITATIONAL * MASS_SOLAR * MASS_EARTH / ASTRONOMICAL_UNIT**2, "\n";
print "\n";


for (my $i = 0; $i < $count; $i++) {
	$force = GRAVITATIONAL * MASS_SOLAR * MASS_EARTH / ASTRONOMICAL_UNIT**2;
}

