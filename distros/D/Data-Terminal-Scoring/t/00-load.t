#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::Terminal::Scoring' ) || print "Bail out!\n";
}

diag( "Testing Data::Terminal::Scoring $Data::Terminal::Scoring::VERSION, Perl $], $^X" );
