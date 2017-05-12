#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'DBX::Simple' ) || print "Bail out!\n";
}

diag( "Testing DBX::Simple $DBX::Simple::VERSION, Perl $], $^X" );
