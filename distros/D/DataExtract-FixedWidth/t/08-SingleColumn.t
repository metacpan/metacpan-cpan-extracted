#!/usr/bin/env perl
use strict;
use warnings;

use feature ':5.10';

use File::Spec;
use DataExtract::FixedWidth;
use Test::More tests => 4;

my $file = File::Spec->catfile( 't', 'data', 'SingleCol.txt' );
open ( my $fh, $file ) || die "Can not open $file";

my @lines = <$fh>;

my $fw = DataExtract::FixedWidth->new({ heuristic => \@lines });

foreach my $idx ( 0 .. @lines ) {
	my $row = $fw->parse( $lines[$idx] );
	my $col = $row->[0];

	given ( $idx ) {
		when ( 0 ) { ok ( !defined $col, 'undef header row' ) }
		when ( 1 ) { ok ( $col eq 'a', "Wanted 'a', got '$col'" ) }
		when ( 2 ) { ok ( $col eq 'b', 'resp b' ) }
		when ( 3 ) { ok ( $col eq 'cccccccc', "Wanted 'cccccccc', got '$col'" ) }
	}

}

