
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
    'lib/Alien/BCM2835.pm',
    't/00-all_prereqs.t',
    't/00-compile.t',
    't/00-compile/lib_Alien_BCM2835_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/00.t',
    't/000-report-versions.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/release-changes_has_content.t',
    't/release-distmeta.t',
    't/release-fixme.t',
    't/release-has-version.t',
    't/release-kwalitee.t',
    't/release-meta-json.t',
    't/release-pause-permissions.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
