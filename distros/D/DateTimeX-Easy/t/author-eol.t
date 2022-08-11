
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
    'lib/DateTimeX/Easy.pm',
    'lib/DateTimeX/Easy/DateParse.pm',
    't/00-load.t',
    't/01-basic.t',
    't/02-tz-parse.t',
    't/03-parse.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/release/boilerplate.t',
    't/release/pod-coverage.t',
    't/release/pod.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
