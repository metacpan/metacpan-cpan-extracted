#!perl
use strict;
use Test::More tests => 5;

# Test script associated with bug reports

require_ok('Astro::Coords');
require_ok('Astro::Telescope');


# Bug 20050216: Unable to parse the dec field
# The problem is that the 'e|E' caused the code to assume
# sexagesimal parsing
my $c = new Astro::Coords( 'ra' => '4.97418832778931',
                           'name' => 'Enter blank sky coords.',
                           'type' => 'J2000',
                           'dec' => '-1.45444100780878e-05');
isa_ok( $c, "Astro::Coords");
my ($ra,$dec) = $c->radec;
$ra->str_ndp(1);
is("$ra","19:00:00.0", "check RA");
is("$dec","-00:00:03.00", "check dec");

