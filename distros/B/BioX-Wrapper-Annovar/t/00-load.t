#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'BioX::Wrapper::Annovar' ) || print "Bail out!\n";
}

diag( "Testing BioX::Wrapper::Annovar $BioX::Wrapper::Annovar::VERSION, Perl $], $^X" );
