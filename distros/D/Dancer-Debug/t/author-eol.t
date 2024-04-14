
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
    'lib/Dancer/Debug.pm',
    'lib/Plack/Middleware/Debug/Dancer/App.pm',
    'lib/Plack/Middleware/Debug/Dancer/Logger.pm',
    'lib/Plack/Middleware/Debug/Dancer/Routes.pm',
    'lib/Plack/Middleware/Debug/Dancer/Session.pm',
    'lib/Plack/Middleware/Debug/Dancer/Settings.pm',
    'lib/Plack/Middleware/Debug/Dancer/Version.pm',
    't/00_compile.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
