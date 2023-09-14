package main;

use strict;
use warnings;

use lib qw{ inc };

use Test::More 0.88;

use My::Module::Test::App;
use My::Module::Test::Mock_App;

use Astro::App::Satpass2::Format::Dump;

my $app = My::Module::Test::Mock_App->new();

klass( 'Astro::App::Satpass2::Format::Dump' );

call_m( 'new', parent => $app, INSTANTIATE, 'Instantiate' );

done_testing;

1;

# ex: set textwidth=72 :
