
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
    'lib/AnyEvent/OWNet.pm',
    'lib/AnyEvent/OWNet/Constants.pm',
    'lib/AnyEvent/OWNet/Response.pm',
    't/01-constants.t',
    't/01-message.t',
    't/01-simple.t',
    't/02-devices.t',
    't/Helpers.pm',
    't/author-critic.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-no404s.t',
    't/author-pod-syntax.t',
    't/author-synopsis.t',
    't/release-common_spelling.t',
    't/release-kwalitee.t',
    't/release-pod-linkcheck.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
