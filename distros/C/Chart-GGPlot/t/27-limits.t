#!perl

use Chart::GGPlot::Setup qw(:base :pdl);

use Test2::V0;
use Test2::Tools::PDL;

use Chart::GGPlot::Limits qw(:all);

subtest xlim => sub {
    my $lims = xlim(0, 1);
    isa_ok($lims, [qw(Chart::GGPlot::Scale::Continuous)]);
    pdl_is($lims->limits, pdl([0, 1]));
};

done_testing();
