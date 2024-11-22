#!perl

use strict;
use warnings;

use Test::More;
use File::ShareDir qw(dist_file dist_dir);

use_ok('Chart::ECharts');

done_testing();

diag("Chart::ECharts $Chart::ECharts::VERSION, Perl $], $^X");
