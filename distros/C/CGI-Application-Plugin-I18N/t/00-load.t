#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CGI::Application::Plugin::I18N' );
}

diag( "Testing CGI::Application::Plugin::I18N $CGI::Application::Plugin::I18N::VERSION, Perl $], $^X" );
