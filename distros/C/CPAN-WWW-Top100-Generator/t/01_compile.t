#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use Test::Script;

ok( $] >= 5.008, 'Perl version is new enough' );

use_ok( 'CPAN::WWW::Top100::Generator' );

script_compiles_ok( 'script/cpantop100' );
