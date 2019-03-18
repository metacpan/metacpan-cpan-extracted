#!perl

use Chart::GGPlot::Setup;

use Test2::V0;

use Chart::GGPlot::Params;

my $p = Chart::GGPlot::Params->new( a => 1, b => 2, c => 3 );
ok($p, 'construction');

done_testing;
