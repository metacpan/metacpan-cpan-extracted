#!perl

use Chart::GGPlot::Setup;

use Data::Frame;
use Data::Frame::Examples qw(mtcars);

use Test2::V0;

use Chart::GGPlot::Facet;
use Chart::GGPlot::Facet::Functions qw(:all);

my $mtcars = mtcars();

pass();

done_testing();
