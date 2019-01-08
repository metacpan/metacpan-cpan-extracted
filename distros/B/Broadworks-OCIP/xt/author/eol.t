use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Broadworks/OCIP.pm',
    'lib/Broadworks/OCIP/Deprecated.pm',
    'lib/Broadworks/OCIP/Deprecated.pod',
    'lib/Broadworks/OCIP/Methods.pm',
    'lib/Broadworks/OCIP/Methods.pod',
    'lib/Broadworks/OCIP/Response.pm',
    'lib/Broadworks/OCIP/Throwable.pm',
    'lib/Redcentric/Roles/OCIP.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
