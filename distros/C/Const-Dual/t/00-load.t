#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Const::Dual' ) || print "Bail out!\n";
}

diag( "Testing Const::Dual $Const::Dual::VERSION, Perl $], $^X" );
