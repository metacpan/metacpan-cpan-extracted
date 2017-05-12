#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'AnyEvent::XMLRPC' ) || print "Bail out!\n";
}

diag( "Testing AnyEvent::XMLRPC $AnyEvent::XMLRPC::VERSION, Perl $], $^X" );
