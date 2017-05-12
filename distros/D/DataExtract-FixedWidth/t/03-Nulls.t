#!/usr/bin/env perl
## Quick test for null_as_undef
use strict;
use warnings;
use feature ':5.10';

use Test::More tests => 12;
use File::Spec;
use DataExtract::FixedWidth;

my $file = File::Spec->catfile( 't', 'data', 'Nulls.txt' );
open ( my $fh, $file ) || die "Can not open $file";

while ( my $line = <$fh> ) {
	state $fw;

	if ( $. == 1 ) {
		$fw = DataExtract::FixedWidth->new({
			header_row => $line
			, null_as_undef => 1
		});
	}
	else {
		my $arrRef = $fw->parse( $line );
		my $hashRef = $fw->parse_hash( $line );

		given ( $. ) {
			when ( 2 ) {
				ok ( $hashRef->{id} eq 1, "Testing output (->parse_hash)" );
				ok ( $hashRef->{name} eq 'Amy', "Testing output (->parse_hash)" );
				ok ( !defined $hashRef->{team}, "Testing output (->parse_hash)" );
				
				ok ( $arrRef->[0] eq '1', "Testing output (->parse)" );
				ok ( $arrRef->[1] eq 'Amy', "Testing output (->parse)" );
				ok ( !defined $arrRef->[2], "Testing output (->parse)" );
			};
			when ( 3 ) {
				ok ( !defined $hashRef->{id}, "Testing output (->parse_hash)" );
				ok ( $hashRef->{name} eq 'Amy', "Testing output (->parse_hash)" );
				ok ( $hashRef->{team} eq 'Reds', "Testing output (->parse_hash)" );
				
				ok ( !defined $arrRef->[0], "Testing output (->parse)" );
				ok ( $arrRef->[1] eq 'Amy', "Testing output (->parse)" );
				ok ( $arrRef->[2] eq 'Reds', "Testing output (->parse)" );
			};
		};

	}

}
