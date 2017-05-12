
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
    'bin/dest',
    'lib/App/Dest.pm',
    't/00-compile.t',
    't/TestLib.pm',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/deploy.t',
    't/init.t',
    't/prereqs.t',
    't/release-kwalitee.t',
    't/release-portability.t',
    't/release-synopsis.t',
    't/status.t',
    't/watches.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
