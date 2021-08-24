use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Config/XrmDatabase.pm',
    'lib/Config/XrmDatabase/Constants.pm',
    'lib/Config/XrmDatabase/Failure.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/insert_resource.t',
    't/kv.t',
    't/parse_name.t',
    't/query_resource.t',
    't/read_file.t',
    't/write_file.t'
);

notabs_ok($_) foreach @files;
done_testing;
