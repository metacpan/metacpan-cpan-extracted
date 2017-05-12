#!/usr/bin/env perl
## AIX Example provided by Russel Adams
## .....    lspv -p hdisk0
## Column headers explicitly provided
use strict;
use warnings;
use feature ':5.10';

use Test::More tests => 13;
use File::Spec;
use DataExtract::FixedWidth;

my $file = File::Spec->catfile( 't', 'data', 'RusselAdams-Snap.txt' );
open ( my $fh, $file ) || die "Can not open $file";

my $fw;
while ( my $line = <$fh> ) {

	if ( $. == 1 ) {
		$fw = DataExtract::FixedWidth->new({
			header_row => $line
			, cols     => [
				qw/STATE REGION TYPE/
				, 'PP RANGE'
				, 'MOUNT POINT'
				, 'LV NAME'
			]
		});
		ok ( $fw->unpack_string eq 'a10a8a14a20a11A*'
			, 'Testing hard coded prerendered unpack string'
				. ' Expected a10a8a14a20a11A'
				. ' got ' . $fw->unpack_string
		);
	}
	else {
		my $arrRef = $fw->parse( $line );
		my $hashRef = $fw->parse_hash( $line );

		given ( $. ) {
			when ( 2 ) {
				ok ( $hashRef->{'PP RANGE'} eq '1-1', "Testing output (->parse_hash)" );
				ok ( $hashRef->{'REGION'} eq 'outer edge', "Testing output (->parse_hash)" );
				ok ( $hashRef->{'MOUNT POINT'} eq 'N/A', "Testing output (->parse_hash)" );
				
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

}
