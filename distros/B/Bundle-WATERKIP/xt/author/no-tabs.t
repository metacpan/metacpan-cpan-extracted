use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/get-azure-token.pl',
    'bin/jwt-decrypt.pl',
    'bin/opnpost',
    'bin/parse-phone-number',
    'bin/rm_pm',
    'bin/today-is',
    'lib/Bundle/WATERKIP.pm',
    'lib/Bundle/WATERKIP/CLI/Azure.pm',
    'lib/Bundle/WATERKIP/CLI/Azure/Password.pm',
    'lib/Bundle/WATERKIP/CLI/JWT.pm',
    'lib/Bundle/WATERKIP/CLI/JWT/Validate.pm',
    't/00-compile.t',
    't/01-basic.t'
);

notabs_ok($_) foreach @files;
done_testing;
