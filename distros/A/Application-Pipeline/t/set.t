#!/usr/bin/perl -T

use lib '../lib';
use strict;
use warnings;

use Test::More tests => 4;

use Application::Pipeline;

my $app = bless {}, 'Application::Pipeline';

ok( $app->setPhases( qw( One Two Three Four ) ), 'setPhases runs cleanly' );
ok( eq_array( $app->{_phases}, [ qw( One Two Three Four ) ] ), 'setPhases succeeded' );

ok( $app->setPluginLocations( qw(
        Path::One 4GBad::Path  Another::6BadPath Path::Two::Here3 Three Four:::Bad Four::Good F
  )), 'setPluginLocations runs cleanly' );

ok( eq_array( $app->{_plugin_locations}, [ qw( Path::One Path::Two::Here3 Three Four::Good F ) ] ),
    'setPluginLocations succeeded'
);

