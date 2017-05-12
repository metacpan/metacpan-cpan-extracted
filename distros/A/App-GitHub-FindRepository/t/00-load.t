#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::GitHub::FindRepository' );
}

diag( "Testing App::GitHub::FindRepository $App::GitHub::FindRepository::VERSION, Perl $], $^X" );
