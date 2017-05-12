#!/usr/bin/env perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'DateLocale' )
}

diag( "Testing DateLocale $DateLocale::VERSION, Perl $], $^X" );
