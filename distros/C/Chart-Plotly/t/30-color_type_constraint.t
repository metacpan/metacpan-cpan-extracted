#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;

use Test::Exception tests => 2;

use Chart::Plotly::Trace::Scatter::Marker;

# Same color markers
lives_ok {
    Chart::Plotly::Trace::Scatter::Marker->new( color => 'hsl(0, 100%, 50%)' )
}
'Color as string supported';

# Multiple color markers
lives_ok {
    Chart::Plotly::Trace::Scatter::Marker->new( color => [ 'hsl(0, 100%, 50%)', 'rgb(255, 0, 0)', '#d3d3d3' ] )
}
'Color as array supported';

