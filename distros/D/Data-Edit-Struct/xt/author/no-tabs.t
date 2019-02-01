use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Data/Edit/Struct.pm',
    'lib/Data/Edit/Struct/Types.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/blessed.t',
    't/clone.t',
    't/delete.t',
    't/edit.t',
    't/insert.t',
    't/pop.t',
    't/replace.t',
    't/shift.t',
    't/splice.t',
    't/sxfrm.t',
    't/transform.t'
);

notabs_ok($_) foreach @files;
done_testing;
