#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::Grepl' );
}

diag( "Testing App::Grepl $App::Grepl::VERSION, Perl $], $^X" );
