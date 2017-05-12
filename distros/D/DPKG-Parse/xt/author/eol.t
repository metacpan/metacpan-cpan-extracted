use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/DPKG/Parse.pm',
    'lib/DPKG/Parse/Available.pm',
    'lib/DPKG/Parse/Entry.pm',
    'lib/DPKG/Parse/Packages.pm',
    'lib/DPKG/Parse/Status.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01app.t',
    't/02entry.t',
    't/03available.t',
    't/03status.t',
    't/04packages.t',
    'xt/author/00-compile.t',
    'xt/author/eol.t',
    'xt/author/kwalitee.t',
    'xt/author/no-tabs.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t',
    'xt/release/minimum-version.t',
    'xt/release/mojibake.t',
    'xt/release/pod-coverage.t',
    'xt/release/pod-no404s.t',
    'xt/release/pod-syntax.t',
    'xt/release/portability.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
