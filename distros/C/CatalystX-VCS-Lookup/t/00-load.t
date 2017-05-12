#!/usr/bin/env perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'CatalystX::VCS::Lookup' ) || print "Bail out!\n";
}

diag( "Testing CatalystX::VCS::Lookup $CatalystX::VCS::Lookup::VERSION, Perl $], $^X" );
