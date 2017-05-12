#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'BatchSystem::SBS' );
}

diag( "Testing BatchSystem::SBS $BatchSystem::SBS::VERSION, Perl $], $^X" );
