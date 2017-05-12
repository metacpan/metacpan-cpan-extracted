#!perl -T

use Test::More tests => 1;

BEGIN {
	require_ok( 'CGI::Application::Plugin::DevPopup' );
}

diag( "Testing CGI::Application::Plugin::DevPopup $CGI::Application::Plugin::DevPopup::VERSION, Perl $], $^X" );
