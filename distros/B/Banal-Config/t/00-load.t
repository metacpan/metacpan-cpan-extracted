#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Banal::Config' ) || print "Bail out!\n";
}

diag( "Testing Banal::Config $Banal::Config::VERSION, Perl $], $^X" );
