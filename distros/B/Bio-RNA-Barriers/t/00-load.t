#!perl -T
use 5.012;
use strict;
use warnings;
use Test::More;
use Test::NoWarnings;            # produces one additional test!


BEGIN {
    plan tests => 2;
    use_ok( 'Bio::RNA::Barriers' ) || print "Bail out!\n";
}

diag( "Testing Bio::RNA::Barriers $Bio::RNA::Barriers::VERSION, Perl $], $^X" );

