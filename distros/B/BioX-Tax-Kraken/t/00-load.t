#!perl -T
use 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'BioX::Tax::Kraken' ) || print "Bail out!\n";
}

diag( "Testing BioX::Tax::Kraken $BioX::Tax::Kraken::VERSION, Perl $], $^X" );
