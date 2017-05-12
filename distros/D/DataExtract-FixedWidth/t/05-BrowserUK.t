#!/usr/bin/env perl
## All code shameless ripped, with slight modifications
## from BrowserUK's pm post http://perlmonks.org/?node_id=628059
use strict;
use warnings;
use feature ':5.10';

use Test::More tests => 5;
use File::Spec;
use DataExtract::FixedWidth;

my $file = File::Spec->catfile( 't', 'data', 'BrowserUK.txt' );
open ( my $fh, $file ) || die "Can not open $file";

my @lines = <$fh>;
my $de = DataExtract::FixedWidth->new({ heuristic => \@lines });

foreach my $lineidx ( 1 .. @lines ) {
	my $line = $lines[$lineidx];
	my $arr = $de->parse( $line );

	given ( $lineidx ) {
		when ( 1 ) {
			ok( $arr->[0] cmp 'The First One Here Is Longer.', "Testing response (parse)" );
			ok( $arr->[5] cmp 'MVP', "Testing response (parse)" );
			ok( $arr->[4] cmp '93871', "Testing response (parse)" );
		}
		when ( 5 ) {
			ok( $arr->[1] cmp 'Twin 200 SH', "Testing response (parse)" );
			ok( $arr->[5] cmp 'VRE', "Testing response (parse)" );
		}
	}

}
