#!/usr/bin/env perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CGI::Application::Plugin::CAPTCHA' );
}

diag( "Testing CGI::Application::Plugin::CAPTCHA $CGI::Application::Plugin::CAPTCHA::VERSION, Perl $], $^X" );
