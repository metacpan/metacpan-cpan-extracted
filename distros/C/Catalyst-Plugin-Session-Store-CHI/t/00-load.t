#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Catalyst::Plugin::Session::Store::CHI' ) || print "Bail out!\n";
}

diag( "Testing Catalyst::Plugin::Session::Store::CHI $Catalyst::Plugin::Session::Store::CHI::VERSION, Perl $], $^X" );
