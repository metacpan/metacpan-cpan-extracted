package main;

use strict;
use warnings;

use Test2::V0;
use Astro::App::Satpass2::Format::Dump;

use lib qw{ inc };

use My::Module::Test::App;

my $mocker = setup_app_mocker;
my $app = Astro::App::Satpass2->new();

klass( 'Astro::App::Satpass2::Format::Dump' );

call_m( 'new', parent => $app, INSTANTIATE, 'Instantiate' );

done_testing;

1;

# ex: set textwidth=72 :
