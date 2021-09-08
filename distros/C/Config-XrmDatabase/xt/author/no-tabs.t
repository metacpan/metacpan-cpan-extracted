use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Config/XrmDatabase.pm',
    'lib/Config/XrmDatabase/Failure.pm',
    'lib/Config/XrmDatabase/Types.pm',
    'lib/Config/XrmDatabase/Util.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/constructor.t',
    't/insert.t',
    't/kv.t',
    't/merge.t',
    't/parse_name.t',
    't/query.t',
    't/read_file.t',
    't/write_file.t'
);

notabs_ok($_) foreach @files;
done_testing;
