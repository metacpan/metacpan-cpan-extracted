#!/usr/bin/perl -w

use strict;
use Convert::Ethiopic::Number;

# use diagnostics;

main:
{

	die ( "usage: $0 <string1> <string2> ..." ) unless ( @ARGV );

	my $n = new Convert::Ethiopic::Number ( );

	foreach ( @ARGV ) {
		$n->number ( $_ );
		print $n->convert, "\n";
	}

}
