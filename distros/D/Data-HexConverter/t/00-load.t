#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::HexConverter' ) || print "Bail out!\n";
}

diag( "Testing Data::HexConverter $Data::HexConverter::VERSION, Perl $], $^X" );
