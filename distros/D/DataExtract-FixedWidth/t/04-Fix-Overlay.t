#!/usr/bin/env perl
## Quick test for fix_overlay
use strict;
use warnings;
use feature ':5.10';

use Test::More tests => 3;
use File::Spec;
use DataExtract::FixedWidth;

my $file = File::Spec->catfile( 't', 'data', 'Fix-Overlay.txt' );
open ( my $fh, $file ) || die "Can not open $file";

while ( my $line = <$fh> ) {
	state $fw;

	if ( $. == 1 ) {
		$fw = DataExtract::FixedWidth->new({
			header_row => $line
			, fix_overlay => 1
		});
	}
	else {
		my $arrRef = $fw->parse( $line );
		my $hashRef = $fw->parse_hash( $line );

		given ( $. ) {
			when ( 2 ) {
				ok ( $hashRef->{id} eq 1, "Testing output (->parse_hash)" );
				ok ( $hashRef->{name} eq 'Amy is foobared', "Testing output (->parse_hash)" );
				ok ( $hashRef->{team} eq 'She likes the bulls.', "Testing output (->parse_hash)" );
			};
		};

	}

}
