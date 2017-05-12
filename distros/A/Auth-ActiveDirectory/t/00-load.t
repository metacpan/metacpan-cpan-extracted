#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Auth::ActiveDirectory' ) || print "Bail out!\n";
}

diag( "Testing Auth::ActiveDirectory $Auth::ActiveDirectory::VERSION, Perl $], $^X" );
