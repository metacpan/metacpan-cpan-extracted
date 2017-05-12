#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::GitHub::FixRepositoryName' );
}

diag( "Testing App::GitHub::FixRepositoryName $App::GitHub::FixRepositoryName::VERSION, Perl $], $^X" );
