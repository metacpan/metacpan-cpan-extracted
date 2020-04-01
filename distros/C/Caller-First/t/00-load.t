#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Caller::First' ) || print "Bail out!\n";
}

diag( "Testing Caller::First $Caller::First::VERSION, Perl $], $^X" );
