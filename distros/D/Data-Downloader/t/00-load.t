#!/usr/bin/env perl

# Pragmas
use strict;
use warnings;

# Modules
use Test::More tests => 3;
use t::lib::functions;


BEGIN {
    use_ok( 'Data::Downloader' );
    use_ok( 'Data::Downloader' );
}

diag( "Testing Data::Downloader $Data::Downloader::VERSION, Perl $], $^X" );

ok(test_cleanup(), "Test clean up");
