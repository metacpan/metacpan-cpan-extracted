#!/usr/bin/env perl
## Example from http://en.wikipedia.org/w/index.php?title=Flat_file_database&oldid=209112999
## Default options with column header name deduction
use strict;
use warnings;
use feature ':5.10';


use Test::More tests => 18;
use DataExtract::FixedWidth;
use File::Spec;

my $file = File::Spec->catfile( 't', 'data', 'Wikipedia.txt' );
open ( my $fh, $file ) || die "Can not open $file";

my $fw;
while ( my $line = <$fh> ) {

	if ( $. == 1 ) {
		$fw = DataExtract::FixedWidth->new({
			header_row => $line
		});
	}
	else {
		my $arrRef = $fw->parse( $line );
		my $hashRef = $fw->parse_hash( $line );

		given ( $. ) {
			when ( 2 ) {
				ok ( $hashRef->{name} eq 'Amy', "Testing output (->parse_hash)" );
				ok ( $hashRef->{team} eq 'Blues', "Testing output (->parse_hash)" );
				ok ( $hashRef->{id} eq '1', "Testing output (->parse_hash)" );
				
				ok ( $arrRef->[0] eq '1', "Testing output (->parse)" );
				ok ( $arrRef->[1] eq 'Amy', "Testing output (->parse)" );
				ok ( $arrRef->[2] eq 'Blues', "Testing output (->parse)" );
			};
			when ( 6 ) {
				ok ( $hashRef->{id} eq '5', "Testing output (->parse_hash)" );
				ok ( $hashRef->{name} eq 'Ethel', "Testing output (->parse_hash)" );
				ok ( $hashRef->{team} eq 'Reds', "Testing output (->parse_hash)" );
				
				ok ( $arrRef->[0] eq '5', "Testing output (->parse)" );
				ok ( $arrRef->[1] eq 'Ethel', "Testing output (->parse)" );
				ok ( $arrRef->[2] eq 'Reds', "Testing output (->parse)" );
			};
			when ( 9 ) {
				ok ( $hashRef->{id} eq '8', "Testing output (->parse_hash)" );
				ok ( $hashRef->{name} eq 'Hank', "Testing output (->parse_hash)" );
				ok ( $hashRef->{team} eq 'Reds', "Testing output (->parse_hash)" );
				
				ok ( $arrRef->[0] eq '8', "Testing output (->parse)" );
				ok ( $arrRef->[1] eq 'Hank', "Testing output (->parse)" );
				ok ( $arrRef->[2] eq 'Reds', "Testing output (->parse)" );
			};
		};

	}

}
