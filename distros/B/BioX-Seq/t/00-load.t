#!perl -T
use 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'BioX::Seq' ) || print "Bail out!\n";
}

diag( "Testing BioX::Seq $BioX::Seq::VERSION, Perl $], $^X" );
