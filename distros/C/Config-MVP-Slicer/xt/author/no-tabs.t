use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Config/MVP/Slicer.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/match_name.t',
    't/match_package.t',
    't/merge-hash.t',
    't/merge-object.t',
    't/plugin_info.t',
    't/separator_regexp.t',
    't/slice.t'
);

notabs_ok($_) foreach @files;
done_testing;
