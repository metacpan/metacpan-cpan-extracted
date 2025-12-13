
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::EOLTests 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/App/TimeTracker/Command/Jira.pm',
    't/00-load.t',
    't/000-report-versions.t',
    't/perlcriticrc'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
