#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'CatalystX::InjectComponent' );
}

diag( "Testing CatalystX::InjectComponent $CatalystX::InjectComponent::VERSION, Perl $], $^X" );
