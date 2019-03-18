#!perl

use strict;
use warnings;

use Test2::V0;

use Chart::GGPlot::Setup;
use Chart::GGPlot::Setup qw(:base);
use Chart::GGPlot::Setup qw(:class);
use Chart::GGPlot::Setup qw(:pdl);

pass("Chart::GGPlot::Setup successfully loaded");

require Chart::GGPlot::Class;
Chart::GGPlot::Class->import();

pass("Chart::GGPlot::Class successfully loaded");

# TODO: cannot load Moose and Moose::Role together in one file
#require Chart::GGPlot::Role;
#Chart::GGPlot::Role->import();
#pass("Chart::GGPlot::Role successfully loaded");

like(
    dies { Chart::GGPlot::Setup->import(":doesnotexist"); },
    qr/^":doesnotexist" is not exported by the Chart::GGPlot::Setup module/,
    "dies on a wrong import parameter"
);

done_testing;
