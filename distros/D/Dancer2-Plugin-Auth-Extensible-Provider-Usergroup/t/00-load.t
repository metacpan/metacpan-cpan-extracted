#!perl -T
use 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Dancer2::Plugin::Auth::Extensible::Provider::Usergroup' ) || print "Bail out!\n";
}

diag( "Testing Dancer2::Plugin::Auth::Extensible::Provider::Usergroup $Dancer2::Plugin::Auth::Extensible::Provider::Usergroup::VERSION, Perl $], $^X" );
