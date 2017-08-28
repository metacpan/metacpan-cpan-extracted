#!perl -T
use 5.14;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'API::Drip' ) || print "Bail out!\n";
}

diag( "Testing API::Drip $API::Drip::VERSION, Perl $], $^X" );
