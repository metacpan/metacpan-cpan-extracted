use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Command/Interactive.pm',
    'lib/Command/Interactive/Interaction.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/001.t',
    't/basic.t',
    't/interaction.t',
    't/password.t',
    't/pathological.t',
    't/rc/.perlcriticrc',
    't/rc/.perltidyrc',
    't/regex.t',
    't/system_only.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
