use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/groupsecret',
    'lib/App/GroupSecret.pm',
    'lib/App/GroupSecret/Crypt.pm',
    'lib/App/GroupSecret/File.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/02-file.t',
    't/keyfiles/basic.yml',
    't/keyfiles/empty.yml',
    't/keys/foo_rsa',
    't/keys/foo_rsa.pub',
    'xt/author/clean-namespaces.t',
    'xt/author/critic.t',
    'xt/author/eol.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-coverage.t',
    'xt/author/pod-no404s.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t',
    'xt/release/minimum-version.t'
);

notabs_ok($_) foreach @files;
done_testing;
