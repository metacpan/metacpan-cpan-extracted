#!/usr/bin/env perl
use strict;
use warnings;
use feature ':5.10';

use Test::More tests => 13;
use File::Spec;
use DataExtract::FixedWidth;

my $file = File::Spec->catfile( 't', 'data', 'RusselAdams-Snap.txt' );
open ( my $fh, $file ) || die "Can not open $file";

my @lines = <$fh>;
my $fw = DataExtract::FixedWidth->new({ heuristic => \@lines });

ok ( $fw->unpack_string eq 'a10a8a14a20a11A*'
	, 'Testing hard coded prerendered unpack string got '
	. $fw->unpack_string
	. ' expected "a10a8a14a20a11A*"'
);

foreach my $idx ( 0 .. $#lines ) {
	my $line = $lines[$idx];

	my $arrRef = $fw->parse( $line );
	my $hashRef = $fw->parse_hash( $line );

	given ( $idx + 1 ) {
		when ( 2 ) {
			ok ( $hashRef->{'PP RANGE'} eq '1-1', "Testing output (->parse_hash)"  );
			ok ( $hashRef->{'REGION'} eq 'outer edge', "Testing output (->parse_hash) got " . $hashRef->{'REGION'} );
			ok ( $hashRef->{'MOUNT POINT'} eq 'N/A', "Testing output (->parse_hash) got " . $hashRef->{'MOUNT POINT'} );
			
			ok ( $arrRef->[0] eq '1-1', "Testing output (->parse)" );
			ok ( $arrRef->[2] eq 'outer edge', "Testing output (->parse)" );
			ok ( $arrRef->[5] eq 'N/A', "Testing output (->parse)" );
		};
		when ( 8 ) {
			ok ( $hashRef->{'PP RANGE'} eq '205-217', "Testing output (->parse_hash)" );
			ok ( $hashRef->{'REGION'} eq 'outer middle', "Testing output (->parse_hash)" );
			ok ( $hashRef->{'MOUNT POINT'} eq '', "Testing output (->parse_hash)" );
			
			ok ( $arrRef->[0] eq '205-217', "Testing output (->parse)" );
			ok ( $arrRef->[2] eq 'outer middle', "Testing output (->parse)" );
			ok ( $arrRef->[5] eq '', "Testing output (->parse)" );
		};
	};

}
