#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Common::CLI' );
}

diag( "Testing Common::CLI $Common::CLI::VERSION, Perl $], $^X" );
