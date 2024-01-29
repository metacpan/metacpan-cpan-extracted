use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Database/Temp.pm',
    'lib/Database/Temp/DB.pm',
    'lib/Database/Temp/Driver/CSV.pm',
    'lib/Database/Temp/Driver/Pg.pm',
    'lib/Database/Temp/Driver/SQLite.pm',
    't/integration/database-temp-csv.t',
    't/integration/database-temp-pg.t',
    't/integration/database-temp-sqlite.t',
    't/lib/Database/Temp/Driver/DummyForTesting.pm',
    't/unit/Database/Temp.t',
    't/unit/Database/Temp/DB.t'
);

notabs_ok($_) foreach @files;
done_testing;
