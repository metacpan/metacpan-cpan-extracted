#!perl
# Simple test for Astro::Telescope
# to test constructor

use strict;
use Test::More tests => 2;

require_ok("Astro::Telescope");

# Test unknown telescope
my $tel = new Astro::Telescope( "blah" );
is( $tel, undef, "check unknown telescope" );

