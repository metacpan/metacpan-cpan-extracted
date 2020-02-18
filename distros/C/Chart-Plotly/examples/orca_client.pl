#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Chart::Plotly::Plot;
use Chart::Plotly::Trace::Scatter;
use Chart::Plotly::Image::Orca::Client;

my $plot = Chart::Plotly::Plot->new(traces => [ Chart::Plotly::Trace::Scatter->new( x => [ 1 .. 5 ], y => [ 1 .. 5 ] )]);

Chart::Plotly::Image::Orca::Client::save_image(plot => $plot, file => "TestOrca.png", server => "http://[::]:9999");

