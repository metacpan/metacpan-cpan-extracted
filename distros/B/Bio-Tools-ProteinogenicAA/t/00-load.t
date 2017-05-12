#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib 'lib';

plan tests => 1;

BEGIN {
    use_ok( 'Bio::Tools::ProteinogenicAA' ) || print "Bail out!\n";
}

diag( "Testing Bio::Tools::ProteinogenicAA $Bio::Tools::ProteinogenicAA::VERSION, Perl $], $^X" );
