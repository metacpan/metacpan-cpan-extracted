#!/usr/bin/perl

use Test::More tests => 1;

# Test for successful module load

BEGIN {
    use_ok( 'Catalyst::Plugin::HashedCookies' );
}

diag( "Testing Catalyst::Plugin::HashedCookies $Catalyst::Plugin::HashedCookies::VERSION, Perl $], $^X" );
