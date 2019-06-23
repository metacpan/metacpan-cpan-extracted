#!/usr/bin/env perl -w

use 5.22.0;
use strict;
use warnings;
use Test::More;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";

plan tests => 1;

BEGIN {
    use_ok( 'Astro::Montenbruck' ) || print "Bail out!\n";
}

diag( "Testing Astro::Montenbruck $Astro::Montenbruck::VERSION, Perl $], $^X" );
