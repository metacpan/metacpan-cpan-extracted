#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Archive::Any::Plugin::Rar' );
}

diag( "Testing Archive::Any::Plugin::Rar $Archive::Any::Plugin::Rar::VERSION, Perl $], $^X" );
