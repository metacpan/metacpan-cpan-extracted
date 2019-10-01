
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
    'bin/dest',
    'lib/App/Dest.pm',
    't/00-compile.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/author-synopsis.t',
    't/bin.t',
    't/deploy.t',
    't/deploy/dest.watch',
    't/deploy/log',
    't/deploy/source/001/deploy',
    't/deploy/source/001/revert',
    't/deploy/source/001/verify',
    't/deploy/source/002/deploy',
    't/deploy/source/002/revert',
    't/deploy/source/002/verify',
    't/deploy/source/003/deploy',
    't/deploy/source/003/revert',
    't/deploy/source/003/verify',
    't/deploy/source/004/deploy',
    't/deploy/source/004/revert',
    't/deploy/source/004/verify',
    't/deploy/source/005/deploy',
    't/deploy/source/005/revert',
    't/deploy/source/005/verify',
    't/deploy/source/dest.wrap',
    't/init.t',
    't/init/actions/001/deploy',
    't/init/actions/001/revert',
    't/init/actions/001/verify',
    't/init/actions/002/deploy',
    't/init/actions/002/revert',
    't/init/actions/002/verify',
    't/init/actions2/001/deploy',
    't/init/actions2/001/revert',
    't/init/actions2/001/verify',
    't/init/actions2/002/deploy',
    't/init/actions2/002/revert',
    't/init/actions2/002/verify',
    't/init/dest.watch',
    't/init/dest.watch2',
    't/make.t',
    't/make/actions/001/deploy',
    't/make/actions/001/revert',
    't/make/actions/001/verify',
    't/make/actions/002/deploy',
    't/make/actions/002/revert',
    't/make/actions/002/verify',
    't/make/dest.watch',
    't/release-kwalitee.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
