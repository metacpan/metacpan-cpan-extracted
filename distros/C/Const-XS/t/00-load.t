#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Const::XS' ) || print "Bail out!\n";
}

diag( "Testing Const::XS $Const::XS::VERSION, Perl $], $^X" );
