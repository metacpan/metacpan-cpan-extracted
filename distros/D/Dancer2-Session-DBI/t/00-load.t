#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Dancer2::Session::DBI' ) || print "Bail out!\n";
}

diag( "Testing Dancer2::Session::DBI $Dancer2::Session::DBI::VERSION, Perl $], $^X" );
