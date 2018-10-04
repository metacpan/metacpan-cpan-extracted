#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Catalyst::Plugin::Shorten' ) || print "Bail out!\n";
}

diag( "Testing Catalyst::Plugin::Shorten $Catalyst::Plugin::Shorten::VERSION, Perl $], $^X" );
