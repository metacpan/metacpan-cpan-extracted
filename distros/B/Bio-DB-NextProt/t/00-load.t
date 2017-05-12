#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Bio::DB::NextProt' ) || print "Bail out!\n";
}

diag( "Testing Bio::DB::NextProt $Bio::DB::NextProt::VERSION, Perl $], $^X" );
