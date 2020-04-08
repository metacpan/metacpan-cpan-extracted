#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::LnArray' ) || print "Bail out!\n";
}

diag( "Testing Data::LnArray $Data::LnArray::VERSION, Perl $], $^X" );
