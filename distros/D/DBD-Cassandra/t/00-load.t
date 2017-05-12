#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'DBD::Cassandra' ) || print "Bail out!\n";
}

diag( "Testing DBD::Cassandra $DBD::Cassandra::VERSION, Perl $], $^X" );
