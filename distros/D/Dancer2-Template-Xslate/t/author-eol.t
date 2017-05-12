
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dancer2/Template/Xslate.pm',
    't/00-compile.t',
    't/01-file.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-mojibake.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-spell.t',
    't/author-pod-syntax.t',
    't/author-test-version.t',
    't/release-cpan-changes.t',
    't/release-dist-manifest.t',
    't/release-distmeta.t',
    't/release-kwalitee.t',
    't/release-minimum-version.t',
    't/release-pod-linkcheck.t',
    't/release-portability.t',
    't/release-unused-vars.t',
    't/views/index.tx',
    't/views/layouts/main.tx'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
