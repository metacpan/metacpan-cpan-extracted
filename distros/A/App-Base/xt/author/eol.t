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
    'lib/App/Base/Script/Option.pod',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/common.t',
    't/daemon-supervisor.t',
    't/daemon.t',
    't/option.t',
    't/rc/perlcriticrc',
    't/rc/perltidyrc',
    't/script.t',
    'xt/author/critic.t',
    'xt/author/distmeta.t',
    'xt/author/eol.t',
    'xt/author/minimum-version.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/author/test-version.t',
    'xt/release/common_spelling.t',
    'xt/release/cpan-changes.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
