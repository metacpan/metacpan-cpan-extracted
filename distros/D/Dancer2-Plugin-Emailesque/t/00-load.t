#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Dancer2::Plugin::Emailesque' ) || print "Bail out!\n";
}

diag( "Testing Dancer2::Plugin::Emailesque $Dancer2::Plugin::Emailesque::VERSION, Perl $], $^X" );
