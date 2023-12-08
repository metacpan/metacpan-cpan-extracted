use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

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

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
