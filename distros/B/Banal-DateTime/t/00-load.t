#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Banal::DateTime' ) || print "Bail out!\n";
}

diag( "Testing Banal::DateTime $Banal::DateTime::VERSION, Perl $], $^X" );
