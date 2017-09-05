#!perl -T
use v5.14;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'API::Drip::Request' ) || print "Bail out!\n";
}

diag( "Testing API::Drip::Request $API::Drip::Request::VERSION, Perl $], $^X" );
