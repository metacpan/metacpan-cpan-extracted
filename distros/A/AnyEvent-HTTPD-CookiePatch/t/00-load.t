#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'AnyEvent::HTTPD::CookiePatch' ) || print "Bail out!\n";
}

diag( "Testing AnyEvent::HTTPD::CookiePatch $AnyEvent::HTTPD::CookiePatch::VERSION, Perl $], $^X" );
