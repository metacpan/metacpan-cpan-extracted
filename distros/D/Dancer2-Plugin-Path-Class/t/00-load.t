#!perl -T
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Dancer2::Plugin::Path::Class' ) || print "Bail out!\n";
}

diag( "Testing Dancer2::Plugin::Path::Class $Dancer2::Plugin::Path::Class::VERSION, Perl $], $^X" );
