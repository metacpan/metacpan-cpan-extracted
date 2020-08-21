use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/App/mkpkgconfig.pm',
    'lib/App/mkpkgconfig/PkgConfig.pm',
    'lib/App/mkpkgconfig/PkgConfig/Entry.pm',
    'script/mkpkgconfig',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/Entry.t',
    't/PkgConfig.t',
    't/mkpkgconfig.t'
);

notabs_ok($_) foreach @files;
done_testing;
