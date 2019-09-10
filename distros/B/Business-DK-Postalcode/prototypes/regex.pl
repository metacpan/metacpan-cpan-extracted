#!/usr/bin/perl -w

use strict;

my @numbers = qw(1234 2234 1235 0555 0800 0877);
my $regex = '(0(?:8((?:0(?:0))|(?:7(?:7))))|(?:5(?:5(?:5))))';

foreach my $number (@numbers) {
	#if ($number =~ m/123((?:4)|(?:5))/) {
	if ($number =~ m/$regex/) {
		print "$number matches!\n"; 
	} else {
		print "$number does not match!\n";	
	}
}