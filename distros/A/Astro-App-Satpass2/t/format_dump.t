package main;

use strict;
use warnings;

use lib qw{ inc };

use Test::More 0.88;

BEGIN {
    # We can't use load_or_skip here because My::Module::Test::App makes
    # use of Astro::Coord::ECI::Utils, which contains an unneeded
    # 'use Data::Dumper'.
    eval {
	require Data::Dumper;
	1;
    } or plan skip_all => 'Data::Dumper not available';
}

use My::Module::Test::App;

use Astro::App::Satpass2::Format::Dump;

klass( 'Astro::App::Satpass2::Format::Dump' );

call_m( 'new', INSTANTIATE, 'Instantiate' );

done_testing;

1;

# ex: set textwidth=72 :
