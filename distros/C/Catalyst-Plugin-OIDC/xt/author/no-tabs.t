use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Catalyst/Plugin/OIDC.pm',
    't/00-compile.t',
    't/auth-code-flow-IT.t',
    't/lib/MyCatalystApp/lib/MyCatalystApp.pm',
    't/lib/MyCatalystApp/lib/MyCatalystApp/Controller/Root.pm',
    't/lib/MyCatalystApp/lib/MyCatalystApp/View/JSON.pm',
    't/lib/MyCatalystApp/mycatalystapp.conf',
    't/lib/MyProviderApp/app.pl',
    't/resource-server-IT.t'
);

notabs_ok($_) foreach @files;
done_testing;
