#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;
use JSON;

use Test::More tests => 4;

use Chart::Plotly::Plot;

my $config = { staticPlot => JSON::true };

my $plot_with_config = Chart::Plotly::Plot->new( config => $config );

is_deeply( $plot_with_config->config, $config, 'Plot objects support config options' );

my $hash_from_plot = from_json( $plot_with_config->TO_JSON() );

is_deeply( $hash_from_plot->{config}, $config, 'JSON dump from plot has config option set' );

my $html_from_plot = $plot_with_config->html();

like( $html_from_plot, qr/staticPlot/, 'Options from config are in the html generated' );

# Is config is passed, layout has to be rendered

like( $html_from_plot,
      qr/Plotly\.react\((?<div>[^,]+),(?<traces>[^,]+),(?<layout>[^,]+),(?<config>[^,]+)\)/,
      'Config options are rendered after layout, 4th argument' );

