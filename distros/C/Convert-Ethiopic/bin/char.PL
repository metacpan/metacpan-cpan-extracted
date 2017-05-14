#!/usr/bin/perl -w

use strict;
use Convert::Ethiopic::Char;
use Convert::Ethiopic::String;

# use diagnostics;

main:
{

	die ( "usage: 0 <char> <char> ..." ) unless ( @ARGV );

	my $i = new Convert::Ethiopic::System ( "sera" );

	#
	#  make sure this is also the default
	#
	my $o = new Convert::Ethiopic::System ( "UTF8" );

	my $s = new Convert::Ethiopic::String ( $i, $o );

	my $c = new Convert::Ethiopic::Char ( );

	foreach ( @ARGV ) {
		chop;
		$s->string ( $_ );
		$c->char ( $s->convert );
		if ( $c->isfidel ) {
			print "Yes\n";
		}
		else {
			print "No\n";
		}
	}

}
