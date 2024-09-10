use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/CXC/PDL/Bin1D.pod',
    'lib/CXC/PDL/Bin1D/Utils.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/Bin1D/bin_on_index.t',
    't/Bin1D/error_algo.t',
    't/Bin1D/explicit.t',
    't/Bin1D/internals.t'
);

notabs_ok($_) foreach @files;
done_testing;
