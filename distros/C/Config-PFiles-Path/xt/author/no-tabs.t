use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Config/PFiles/Path.pm',
    't/00-compile.t',
    't/00-load.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/class.t',
    't/export.t',
    't/extract.t',
    't/import0.t',
    't/import_append.t',
    't/import_prepend.t',
    't/import_remove.t',
    't/import_replace.t',
    't/mutator.t',
    't/new.t'
);

notabs_ok($_) foreach @files;
done_testing;
