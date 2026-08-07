#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'DBIx::Loop' ) || print "Bail out!\n";
}

diag( "Testing DBIx::Loop $DBIx::Loop::VERSION, Perl $], $^X" );
