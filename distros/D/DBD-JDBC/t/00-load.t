#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'DBD::JDBC' ) || print "Bail out!\n";
}

diag( "Testing DBD::JDBC $DBD::JDBC::VERSION, Perl $], $^X" );
