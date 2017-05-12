#!/usr/bin/perl
#
#

# This script will decode hex-encoded strings; it helps double-check the library sometimes

use strict;
use warnings;

while(<>) {
	chomp;
	s/^\s*//;
	s/\s*$//;
	next unless $_;

	my(@parts) = split //;
	my(@pairs);
	while( @parts ) {
		my($a) = shift( @parts );
		my($b) = shift( @parts );
		push @pairs, qq($a$b);
	}

#	pop @pairs;

	print( join('', @pairs) . "\n" );

	for my $p (@pairs) {
		my($o) = hex($p);
		use integer;
		unless( (sprintf("%c", $o)) =~ m/[[:alpha:][:alnum:][:digit:][:punct:]]/) {
			$o = 32;
		}
		printf(qq( %c), $o);
	}

	print "\n";
}
