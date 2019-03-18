#!perl

use Chart::GGPlot::Setup;

use Test2::V0;

use Chart::GGPlot::Layer;
use Chart::GGPlot::Layer::Functions qw(:all);

is(
    Chart::GGPlot::Layer->_find_subclass( 'Geom', 'point' ),
    'Chart::GGPlot::Geom::Point',
    'Chart::GGPlot::Layer->_find_subclass'
);
is(
    Chart::GGPlot::Layer->_find_subclass( 'Stat', 'identity' ),
    'Chart::GGPlot::Stat::Identity',
    'Chart::GGPlot::Layer->_find_subclass'
);

done_testing();
