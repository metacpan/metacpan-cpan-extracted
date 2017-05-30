use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/setup-appveyor-yml.pl',
    'bin/setup-travis-yml.pl',
    'lib/App/CISetup.pm',
    'lib/App/CISetup/AppVeyor/ConfigFile.pm',
    'lib/App/CISetup/AppVeyor/ConfigUpdater.pm',
    'lib/App/CISetup/Role/ConfigFile.pm',
    'lib/App/CISetup/Role/ConfigFileFinder.pm',
    'lib/App/CISetup/Travis/ConfigFile.pm',
    'lib/App/CISetup/Travis/ConfigUpdater.pm',
    'lib/App/CISetup/Types.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/appveyor.t',
    't/travis.t'
);

notabs_ok($_) foreach @files;
done_testing;
