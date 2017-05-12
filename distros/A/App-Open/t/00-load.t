#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'App::Open' );
    use_ok( 'App::Open::Config' );
}

diag( "Testing App::Open $App::Open::VERSION, Perl $], $^X" );
