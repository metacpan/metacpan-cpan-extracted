#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CGI::Application::Plugin::Email' );
}

diag( "Testing CGI::Application::Plugin::Email $CGI::Application::Plugin::Email::VERSION, Perl $], $^X" );
