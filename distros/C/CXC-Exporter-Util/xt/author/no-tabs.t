use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/CXC/Exporter/Util.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/all.t',
    't/basic.t',
    't/bugs/backcompat.t',
    't/constants.t',
    't/lib/My/Test/Utils.pm',
    't/types.t'
);

notabs_ok($_) foreach @files;
done_testing;
