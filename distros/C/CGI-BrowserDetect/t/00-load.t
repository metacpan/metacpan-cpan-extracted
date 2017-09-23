#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'CGI::BrowserDetect' ) || print "Bail out!\n";
}

diag( "Testing CGI::BrowserDetect $CGI::BrowserDetect::VERSION, Perl $], $^X" );
