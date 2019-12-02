use strict;
use warnings;

use Test::More;

eval 'use Devel::IPerl';
plan skip_all => 'Devel::IPerl not installed' if $@;

use_ok('Devel::IPerl::Plugin::Chart::Plotly');

done_testing();

