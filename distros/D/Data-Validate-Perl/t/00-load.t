#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::Validate::Perl' ) || print "Bail out!\n";
}

diag( "Testing Data::Validate::Perl $Data::Validate::Perl::VERSION, Perl $], $^X" );
