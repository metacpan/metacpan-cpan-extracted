#!/usr/bin/perl -w

use strict;
use Convert::Ethiopic::String;

# use diagnostics;

main:
{

	die ( "usage: 0 <string1> <string2> ..." ) unless ( @ARGV );

	my $i = new Convert::Ethiopic::System ( "sera" );

	#
	#  make sure this is also the default
	#
	my $o = new Convert::Ethiopic::System ( "UTF8" );

	my $s = new Convert::Ethiopic::String ( $i, $o );
	# my $s = new Convert::Ethiopic::String;

	foreach ( @ARGV ) {
		$s->string ( $_ );
		print $s->convert, "\n";
	}

}
