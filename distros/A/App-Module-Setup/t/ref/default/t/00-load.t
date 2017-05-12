#! perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::Module::Setup' );
}

diag( "Testing App::Module::Setup $App::Module::Setup::VERSION, Perl $], $^X" );
