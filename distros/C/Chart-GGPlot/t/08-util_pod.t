#!perl

use Chart::GGPlot::Setup qw(:base :pdl);

use Test2::V0;

use Chart::GGPlot::Util::Pod qw(layer_func_pod);

my $text = layer_func_pod(<<'EOT');

%TMPL_COMMON_ARGS%

EOT

ok($text !~ /TMPL/, 'layer_func_pod');

done_testing();
