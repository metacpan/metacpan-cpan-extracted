#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Dancer::Plugin::RPC::XML' );
}

diag( "Testing Dancer::Plugin::RPC::XML $Dancer::Plugin::RPC::XML::VERSION, Perl $], $^X" );
