#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Dancer2::Plugin::Flash' ) || print "Bail out!\n";
}

diag( "Testing Dancer2::Plugin::Flash $Dancer2::Plugin::Flash::VERSION, Perl $], $^X" );
