#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'API::Mathpix' ) || print "Bail out!\n";
}

diag( "Testing API::Mathpix $API::Mathpix::VERSION, Perl $], $^X" );
