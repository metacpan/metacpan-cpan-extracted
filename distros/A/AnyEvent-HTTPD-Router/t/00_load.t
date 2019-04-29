#!perl
use 5.008;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'AnyEvent::HTTPD::Router' ) || print "Bail out!\n";
}

diag( "Testing AnyEvent::HTTPD::Router $AnyEvent::HTTPD::Router::VERSION, Perl $], $^X" );