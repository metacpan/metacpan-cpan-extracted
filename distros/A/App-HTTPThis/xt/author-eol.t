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
    'bin/http_this',
    'lib/App/HTTPThis.pm',
    't/00-compile.t',
    'xt/author-distmeta.t',
    'xt/author-eol.t',
    'xt/author-no-tabs.t',
    'xt/author-pod-coverage.t',
    'xt/author-pod-syntax.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
