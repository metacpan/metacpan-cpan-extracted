package main;

use strict;
use warnings;

use lib qw{ inc };

use Test::More 0.88;

use My::Module::Test::App;

use Astro::App::Satpass2::Format::Dump;

klass( 'Astro::App::Satpass2::Format::Dump' );

call_m( 'new', INSTANTIATE, 'Instantiate' );

done_testing;

1;

# ex: set textwidth=72 :
