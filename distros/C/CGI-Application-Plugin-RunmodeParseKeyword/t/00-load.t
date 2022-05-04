#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CGI::Application::Plugin::RunmodeParseKeyword' );
}

diag( "Testing CGI::Application::Plugin::RunmodeParseKeyword $CGI::Application::Plugin::RunmodeParseKeyword::VERSION, Perl $], $^X" );
