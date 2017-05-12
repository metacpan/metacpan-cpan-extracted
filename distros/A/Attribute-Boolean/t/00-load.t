#!perl -T
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Attribute::Boolean' ) || print "Bail out!\n";
}

diag( "Testing Attribute::Boolean $Attribute::Boolean::VERSION, Perl $], $^X" );
