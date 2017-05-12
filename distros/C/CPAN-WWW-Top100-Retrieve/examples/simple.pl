#!/usr/bin/perl
#
# This file is part of CPAN-WWW-Top100-Retrieve
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
use strict; use warnings;

use CPAN::WWW::Top100::Retrieve;
use CPAN::WWW::Top100::Retrieve::Utils qw( types );
use Data::Dumper;

#my $top100 = CPAN::WWW::Top100::Retrieve->new( debug => 1 );
my $top100 = CPAN::WWW::Top100::Retrieve->new;

# The number of dists to display per list
my $display = 5;

# structured output
foreach my $type ( sort @{ types() } ) {
	my $c = 0;
	my $res = $top100->list( $type );
	if ( ! defined $res ) {
		warn $top100->error;
		next;
	}
	foreach my $dist ( @$res ) {
		if ( ++$c > $display ) {
			last;
		}

		print uc( $type ) . " List($c): " . $dist->dist . " (" . $dist->author . ")\n";
	}
	print "\n";
}

# Output all
#print "HEAVY List: " . Dumper( $top100->list( 'heavy' ) );
#print "\n\nVOLATILE List: " . Dumper( $top100->list( 'volatile' ) );
