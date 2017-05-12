#!/usr/bin/perl
#
# changing_constants.pl - calculates constants that vary according to known functions
# Boyd Duffee, Feb 2016

use strict;
use warnings;

my $year = (localtime)[5] + 1900;
my $delta = 5;

print "The tropical year in ", $year - $delta, " is ", 
		sprintf( "%.2f", tropical_year_in_seconds($year - $delta)), " seconds\n";
print "The tropical year in $year is ", 
		sprintf( "%.2f", tropical_year_in_seconds($year)), " seconds\n";
print "The tropical year in ", $year + $delta, " is ", 
		sprintf( "%.2f", tropical_year_in_seconds($year + $delta)), " seconds\n";



exit;

sub tropical_year_in_seconds {
	my $year = shift;
	my $t = ($year - 2000)/100;	# should be Julian centuries from 1/1/2000, close enough

	return 86400 * (365.2421896698-(6.15359e-6 * $t) - (7.29e-10 * $t**2) + (2.64e-10 * $t**3));
}
