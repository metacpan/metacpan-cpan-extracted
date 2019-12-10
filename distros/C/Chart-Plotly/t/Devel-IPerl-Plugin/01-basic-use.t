
use strict;
use warnings;

use Test::More;

eval 'use Devel::IPerl::Plugin::Chart::Plotly';
plan skip_all => "Can't load Devel::IPerl::Plugin::Chart::Plotly. Devel::IPerl not installed"
  if ( $@ =~ /Display(::|\/|\\)HTML/ );

# Loading errors are tested by 00-load-devel_iperl_plugin.t

Devel::IPerl::Plugin::Chart::Plotly->register();

ok( Chart::Plotly::Plot->can('iperl_data_representations') );
ok( Chart::Plotly::Trace::Scatter->can('iperl_data_representations') );
done_testing();

