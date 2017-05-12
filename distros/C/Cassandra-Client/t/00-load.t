#!perl -T
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Cassandra::Client' ) || print "Bail out!\n";
}

diag( "Testing Cassandra::Client $Cassandra::Client::VERSION, Perl $], $^X" );
