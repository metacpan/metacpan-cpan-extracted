#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'CHI::Driver::DBIC' ) || print "Bail out!\n";
}

diag( "Testing CHI::Driver::DBIC $CHI::Driver::DBIC::VERSION, Perl $], $^X" );
