
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
    'bin/yada',
    'lib/AnyEvent/Net/Curl/Const.pm',
    'lib/AnyEvent/Net/Curl/Queued.pm',
    'lib/AnyEvent/Net/Curl/Queued/Easy.pm',
    'lib/AnyEvent/Net/Curl/Queued/Multi.pm',
    'lib/AnyEvent/Net/Curl/Queued/Stats.pm',
    'lib/YADA.pm',
    'lib/YADA/Worker.pm',
    't/00-compile.t',
    't/00-load.t',
    't/01-net-curl-compatibility.t',
    't/02-const.t',
    't/10-stats.t',
    't/20-easy.t',
    't/21-easy-bulk-getset.t',
    't/30-queued-single.t',
    't/31-queued.t',
    't/40-loopback.t',
    't/41-loopback-cb.t',
    't/42-loopback-retry.t',
    't/43-loopback-yada.t',
    't/44-yada-simple.t',
    't/50-recursion.t',
    't/60-cleanup.t',
    't/61-nest.t',
    't/70-timeout.t',
    't/71-bad-address.t',
    't/72-non-http.t',
    't/73-cycle.t',
    't/74-exception.t',
    't/Loopbacker.pm',
    't/Recursioner.pm',
    't/Retrier.pm',
    't/Timeouter.pm',
    't/author-critic.t',
    't/author-distmeta.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-mojibake.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-linkcheck.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/author-synopsis.t',
    't/author-test-version.t',
    't/release-cpan-changes.t',
    't/release-dist-manifest.t',
    't/release-kwalitee.t',
    't/release-unused-vars.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
