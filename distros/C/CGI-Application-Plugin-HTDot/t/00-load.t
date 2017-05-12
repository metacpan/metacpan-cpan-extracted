#!/usr/bin/env perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CGI::Application::Plugin::HTDot' );
}

diag( "Testing CGI::Application::Plugin::HTDot $CGI::Application::Plugin::HTDot::VERSION, Perl $], $^X" );
