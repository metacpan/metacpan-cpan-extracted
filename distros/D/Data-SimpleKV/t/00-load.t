#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::SimpleKV' ) || print "Bail out!\n";
}

diag( "Testing Data::SimpleKV $Data::SimpleKV::VERSION, Perl $], $^X" );
