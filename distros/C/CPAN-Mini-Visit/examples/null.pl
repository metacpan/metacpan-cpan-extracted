#!/usr/bin/perl

# Tests expansion (with no processing) of an entire minicpan.
# Stops at the end to allow analysis of memory consumption.

use strict;
use CPAN::Mini::Visit;

unless ( $ARGV[0] and -d $ARGV[0] ) {
	die "Missing or invalid minicpan directory";
}

CPAN::Mini::Visit->new(
	minicpan => $ARGV[0],
	callback => sub {
		print "$_[0]->{counter} - $_[0]->{dist}\n";
	},
)->run;

print "CPAN::Mini::Visit->run completed\n";
sleep 10000000;
