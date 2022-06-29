use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/git-codeowners',
    'lib/App/Codeowners.pm',
    'lib/App/Codeowners/Formatter.pm',
    'lib/App/Codeowners/Formatter/CSV.pm',
    'lib/App/Codeowners/Formatter/JSON.pm',
    'lib/App/Codeowners/Formatter/String.pm',
    'lib/App/Codeowners/Formatter/TSV.pm',
    'lib/App/Codeowners/Formatter/Table.pm',
    'lib/App/Codeowners/Formatter/YAML.pm',
    'lib/App/Codeowners/Options.pm',
    'lib/App/Codeowners/Util.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/app-codeowners-util.t',
    't/app-codeowners.t',
    'xt/author/critic.t',
    'xt/author/distmeta.t',
    'xt/author/eol.t',
    'xt/author/minimum-version.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-coverage.t',
    'xt/author/pod-no404s.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/release/consistent-version.t',
    'xt/release/cpan-changes.t'
);

notabs_ok($_) foreach @files;
done_testing;
