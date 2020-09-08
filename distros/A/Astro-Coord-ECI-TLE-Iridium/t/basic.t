package main;

use strict;
use warnings;

use Test::More 0.88;

require_ok 'Astro::Coord::ECI::TLE::Iridium'
    or BAIL_OUT 'Can not continue without Astro::Coord::ECI::Iridium';

done_testing;

1;

# ex: set textwidth=72 :
