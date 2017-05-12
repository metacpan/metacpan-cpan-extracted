#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Plugin::ErrorCatcher::ActiveMQ::Stomp' );
}

diag( "Testing Catalyst::Plugin::ErrorCatcher::ActiveMQ::Stomp $Catalyst::Plugin::ErrorCatcher::ActiveMQ::Stomp::VERSION, Perl $], $^X" );
