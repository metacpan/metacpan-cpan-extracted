#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::Matt::Daemon' );
}

diag( "Testing Acme::Matt::Daemon $Acme::Matt::Daemon::VERSION, Perl $], $^X" );
