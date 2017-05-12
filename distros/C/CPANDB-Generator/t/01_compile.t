#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;
use Test::Script;

ok( $] >= 5.008005, 'Perl version is new enough' );

use_ok( 'CPANDB::Generator' );
use_ok( 'CPANDB::Generator::GetIndex' );
script_compiles_ok( 'script/cpandb-generate' );
