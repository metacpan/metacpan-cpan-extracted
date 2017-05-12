#!/usr/bin/perl

while (<DATA>) {
	chomp;
	my ($c, $v) = split /\t+/;

	$v =~ s/\sx\s10/e/;
	$v =~ s/ /_/g;
	print "\tis($c, $v, '$c');\n";
}

__DATA__
AVOGADRO	6.022 140 857 x 1023
THOMSON_CROSS_SECTION	0.665 245 871 58 x 10-28
MASS_ELECTRON	9.109 383 56 x 10-31
MASS_PROTON		1.672 621 898 x 10-27
MASS_NEUTRON	1.674 927 471 x 10-27
RADIUS_ELECTRON	2.817 940 3227 x 10-15
RADIUS_BOHR		0.529 177 210 67 x 10-10
MASS_ALPHA		6.644 657 230 x 10-27
