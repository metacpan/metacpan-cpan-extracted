#!perl -T
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Dancer2::Plugin::Auth::ActiveDirectory' ) || print "Bail out!\n";
}

diag( "Testing Dancer2::Plugin::Auth::ActiveDirectory $Dancer2::Plugin::Auth::ActiveDirectory::VERSION, Perl $], $^X" );
