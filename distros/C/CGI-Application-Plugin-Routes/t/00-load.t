#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CGI::Application::Plugin::Routes' );
}

diag( "Testing CGI::Application::Plugin::Routes $CGI::Application::Plugin::Routes::VERSION, Perl $], $^X" );
