use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.13

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Catalyst/Controller/ActionRole.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/action-class.t',
    't/basic.t',
    't/basic_rest.t',
    't/execution-via-config.t',
    't/execution-via-does.t',
    't/lib/Catalyst/Action/TestActionClass.pm',
    't/lib/Catalyst/ActionRole/Moo.pm',
    't/lib/Catalyst/ActionRole/Zoo.pm',
    't/lib/Moo.pm',
    't/lib/TestApp.pm',
    't/lib/TestApp/ActionRole/Boo.pm',
    't/lib/TestApp/ActionRole/First.pm',
    't/lib/TestApp/ActionRole/Kooh.pm',
    't/lib/TestApp/ActionRole/Moo.pm',
    't/lib/TestApp/ActionRole/Second.pm',
    't/lib/TestApp/ActionRole/Shared.pm',
    't/lib/TestApp/Controller/ActionClass.pm',
    't/lib/TestApp/Controller/Bar.pm',
    't/lib/TestApp/Controller/Boo.pm',
    't/lib/TestApp/Controller/ExecutionViaConfig.pm',
    't/lib/TestApp/Controller/ExecutionViaDoes.pm',
    't/lib/TestApp/Controller/Foo.pm',
    't/lib/TestAppREST.pm',
    't/lib/TestAppREST/ActionRole/Moo.pm',
    't/lib/TestAppREST/Controller/Foo.pm',
    'xt/author/00-compile.t',
    'xt/author/eol.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-spell.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t',
    'xt/release/kwalitee.t',
    'xt/release/minimum-version.t',
    'xt/release/mojibake.t',
    'xt/release/pod-coverage.t',
    'xt/release/pod-no404s.t',
    'xt/release/pod-syntax.t',
    'xt/release/portability.t'
);

notabs_ok($_) foreach @files;
done_testing;
