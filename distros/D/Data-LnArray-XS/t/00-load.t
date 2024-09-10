#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::LnArray::XS' ) || print "Bail out!\n";
}

diag( "Testing Data::LnArray::XS $Data::LnArray::XS::VERSION, Perl $], $^X" );
