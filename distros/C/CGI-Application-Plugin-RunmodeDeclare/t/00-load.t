#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CGI::Application::Plugin::RunmodeDeclare' );
}

diag( "Testing CGI::Application::Plugin::RunmodeDeclare $CGI::Application::Plugin::RunmodeDeclare::VERSION, Perl $], $^X" );
