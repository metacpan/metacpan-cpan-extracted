#!perl -T

use Test::More tests => 1;

use base 'CGI::Application';

BEGIN {
	use_ok( 'CGI::Application::Plugin::MessageStack' );
}

diag( "Testing CGI::Application::Plugin::MessageStack $CGI::Application::Plugin::MessageStack::VERSION, Perl $], $^X" );
