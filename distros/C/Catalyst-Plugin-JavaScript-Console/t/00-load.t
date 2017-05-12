#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Catalyst::Plugin::JavaScript::Console' ) || print "Bail out!\n";
}

diag( "Testing Catalyst::Plugin::JavaScript::Console $Catalyst::Plugin::JavaScript::Console::VERSION, Perl $], $^X" );
