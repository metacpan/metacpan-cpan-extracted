#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;

ok( $] >= 5.005, 'Perl version is new enough' );

use_ok( 'Algorithm::Dependency::Source::DBI' );

SKIP: {
	unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING}  ) {
		skip('CPAN Testers code not needed for install', 1);
	}
	use_ok( 't::lib::SQLite::Temp' );
}

