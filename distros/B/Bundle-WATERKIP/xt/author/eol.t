use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/get-azure-token.pl',
    'bin/i3-wod',
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

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
