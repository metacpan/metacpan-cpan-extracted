#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CallOfDuty::LANMapper' );
}

diag( "Testing CallOfDuty::LANMapper $CallOfDuty::LANMapper::VERSION, Perl $], $^X" );
