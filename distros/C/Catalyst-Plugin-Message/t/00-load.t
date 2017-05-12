#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Plugin::Message' );
}

diag( "Testing Catalyst::Plugin::Message $Catalyst::Plugin::Message::VERSION, Perl $], $^X" );
