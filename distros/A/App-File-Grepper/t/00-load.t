#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::File::Grepper' );
}

diag( "Testing App::File::Grepper $App::File::Grepper::VERSION, Perl $], $^X" );
