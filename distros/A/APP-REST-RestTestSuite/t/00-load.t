#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'APP::REST::RestTestSuite' ) || print "Bail out!\n";
}

diag( "Testing APP::REST::RestTestSuite $APP::REST::RestTestSuite::VERSION, Perl $], $^X" );
