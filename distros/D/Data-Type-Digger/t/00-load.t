#!perl -T
use 5.14.0;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::Type::Digger' ) || print "Bail out!\n";
}

diag( "Testing Data::Type::Digger $Data::Type::Digger::VERSION, Perl $], $^X" );
