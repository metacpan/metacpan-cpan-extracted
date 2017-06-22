use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/setup-appveyor-yml.pl',
    'bin/setup-travis-yml.pl',
    'lib/App/CISetup.pm',
    'lib/App/CISetup/AppVeyor/ConfigFile.pm',
    'lib/App/CISetup/AppVeyor/ConfigUpdater.pm',
    'lib/App/CISetup/Role/ConfigFile.pm',
    'lib/App/CISetup/Role/ConfigUpdater.pm',
    'lib/App/CISetup/Travis/ConfigFile.pm',
    'lib/App/CISetup/Travis/ConfigUpdater.pm',
    'lib/App/CISetup/Types.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/bin/travis',
    't/lib/R/Tester.pm',
    't/lib/T/AppVeyor.pm',
    't/lib/T/Shared.pm',
    't/lib/T/Travis.pm',
    't/run-tcm.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
