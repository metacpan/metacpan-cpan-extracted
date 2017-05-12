use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/App/Base.pm',
    'lib/App/Base/Daemon.pm',
    'lib/App/Base/Daemon/Supervisor.pm',
    'lib/App/Base/Script.pm',
    'lib/App/Base/Script/Common.pm',
    'lib/App/Base/Script/OnlyOne.pm',
    'lib/App/Base/Script/Option.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/common.t',
    't/daemon-supervisor.t',
    't/daemon.t',
    't/option.t',
    't/rc/.perlcriticrc',
    't/rc/.perltidyrc',
    't/script.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
