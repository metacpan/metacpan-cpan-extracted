use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dancer2/Plugin/JobScheduler.pm',
    'lib/Dancer2/Plugin/JobScheduler/Client/TheSchwartz.pm',
    't/00-load.t',
    't/01-basic.t',
    't/lib/Dancer2/Plugin/JobScheduler/Testing/TheSchwartz/Database/Schemas/Pg.pm',
    't/lib/Dancer2/Plugin/JobScheduler/Testing/TheSchwartz/Database/Schemas/SQLite.pm',
    't/lib/Dancer2/Plugin/JobScheduler/Testing/Utils.pm',
    't/theschwartz-webapp-all.t',
    't/theschwartz-webapp-submit.t',
    't/theschwartz-webapp.t'
);

notabs_ok($_) foreach @files;
done_testing;
