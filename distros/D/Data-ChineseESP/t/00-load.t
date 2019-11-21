#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::ChineseESP' ) || print "Bail out!\n";
}

diag( "Testing Data::ChineseESP $Data::ChineseESP::VERSION, Perl $], $^X" );
