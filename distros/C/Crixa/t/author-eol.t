
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
    'lib/Crixa.pm',
    'lib/Crixa/Channel.pm',
    'lib/Crixa/Exchange.pm',
    'lib/Crixa/HasMQ.pm',
    'lib/Crixa/Message.pm',
    'lib/Crixa/Queue.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-spell.t',
    't/lib/Test/Crixa/Live.pm',
    't/lib/Test/Crixa/Mocked.pm',
    't/lib/Test/Role/Crixa.pm',
    't/lib/Test/Runner.pm',
    't/release-cpan-changes.t',
    't/release-pod-coverage.t',
    't/release-pod-linkcheck.t',
    't/release-pod-no404s.t',
    't/release-pod-syntax.t',
    't/release-portability.t',
    't/release-synopsis.t',
    't/release-test-version.t',
    't/release-tidyall.t',
    't/run-tests.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
