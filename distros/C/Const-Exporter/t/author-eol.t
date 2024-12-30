
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Const/Exporter.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/10-basic.t',
    't/11-tags.t',
    't/12-blessed.t',
    't/13-is_const.t',
    't/20-example.t',
    't/21-example.t',
    't/author-changes.t',
    't/author-critic.t',
    't/author-cve.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-linkcheck.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/author-vars.t',
    't/empty-with-const.t',
    't/enums.t',
    't/etc/perlcritic.rc',
    't/lib/Test/Const/Exporter/Empty.pm',
    't/lib/Test/Const/Exporter/Enums.pm',
    't/lib/Test/Const/Exporter/Strictures.pm',
    't/release-dist-manifest.t',
    't/release-fixme.t',
    't/release-kwalitee.t',
    't/release-trailing-space.t',
    't/strictures.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
