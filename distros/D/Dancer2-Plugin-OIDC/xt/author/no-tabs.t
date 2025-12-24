use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dancer2/Plugin/OIDC.pm',
    't/00-compile.t',
    't/auth-code-flow-IT.t',
    't/auth-code-flow-IT/MyProviderApp.pl',
    't/auth-code-flow-IT/MyTestApp.pm',
    't/resource-server-IT.t',
    't/resource-server-IT/MyProviderApp.pl',
    't/resource-server-IT/MyTestApp.pm'
);

notabs_ok($_) foreach @files;
done_testing;
