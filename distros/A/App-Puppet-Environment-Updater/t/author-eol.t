
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
    'bin/git-update-environment',
    'bin/git-update-production',
    'bin/git-update-staging',
    'bin/git-update-testing',
    'lib/App/Puppet/Environment/Updater.pm',
    't/00-compile.t',
    't/000-report-versions-tiny.t',
    't/app.puppet.environment.updater.t',
    't/author-critic.t',
    't/author-distmeta.t',
    't/author-eol.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/lib/App/Puppet/Environment/UpdaterTest.pm',
    't/release-cpan-changes.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
