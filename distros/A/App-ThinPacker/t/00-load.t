#!/usr/bin/perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::ThinPacker' );
}

diag( "Testing App::ThinPakcer $App::ThinPacker::VERSION, Perl $], $^X" );
