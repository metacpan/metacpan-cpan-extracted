
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.14

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/App/autotest.pm',
    'lib/App/autotest/Test/Runner.pm',
    'lib/App/autotest/Test/Runner/Result.pm',
    'lib/App/autotest/Test/Runner/Result/History.pm',
    'scripts/autotest',
    't/author-critic.t',
    't/features/things_just_got_better_message.t',
    't/helper.pm',
    't/integration/autotest.t',
    't/integration/tap-harness.t',
    't/release-no-tabs.t',
    't/release-pod-syntax.t',
    't/unit/autotest.t',
    't/unit/test_runner.t',
    't/unit/test_runner_result.t',
    't/unit/test_runner_result_history.t'
);

notabs_ok($_) foreach @files;
done_testing;
