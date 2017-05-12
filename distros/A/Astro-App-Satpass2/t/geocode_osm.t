package main;

use 5.008;

use strict;
use warnings;

use lib qw{ inc };

use Test::More 0.88;	# Because of done_testing();
use My::Module::Test::Geocode;

setup	'Astro::App::Satpass2::Geocode::OSM';

SKIP: {
    geocode '10 Downing St, London England', 1;
}

done_testing;

1;

# ex: set textwidth=72 :
