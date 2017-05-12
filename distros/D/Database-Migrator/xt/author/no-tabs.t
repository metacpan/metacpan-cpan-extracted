use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Database/Migrator.pm',
    'lib/Database/Migrator/Core.pm',
    'lib/Database/Migrator/Types.pm',
    'lib/Test/Database/Migrator.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/compile.t'
);

notabs_ok($_) foreach @files;
done_testing;
