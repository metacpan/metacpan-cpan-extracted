#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::CLI::Toolkit' );
}

diag( "Testing App::CLI::Toolkit $App::CLI::Toolkit::VERSION, Perl $], $^X" );
