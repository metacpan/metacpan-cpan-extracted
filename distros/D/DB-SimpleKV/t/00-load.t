#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'DB::SimpleKV' ) || print "Bail out!\n";
}

diag( "Testing DB::SimpleKV $DB::SimpleKV::VERSION, Perl $], $^X" );
