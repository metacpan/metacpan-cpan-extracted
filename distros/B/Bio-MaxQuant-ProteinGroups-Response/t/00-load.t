#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Bio::MaxQuant::ProteinGroups::Response' ) || print "Bail out!\n";
}

diag( "Testing Bio::MaxQuant::ProteinGroups::Response $Bio::MaxQuant::ProteinGroups::Response::VERSION, Perl $], $^X" );
