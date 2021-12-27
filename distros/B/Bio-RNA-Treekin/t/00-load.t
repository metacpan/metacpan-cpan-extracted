#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 1;


BEGIN {
    use_ok( 'Bio::RNA::Treekin' ) || print "Bail out!\n";
}

diag( "Testing Bio::RNA::Treekin $Bio::RNA::Treekin::VERSION, Perl $], $^X" );
