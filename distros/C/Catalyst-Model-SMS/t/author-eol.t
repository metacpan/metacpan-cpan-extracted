
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print "1..0 # SKIP these tests are for testing by the author\n";
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Catalyst/Helper/Model/SMS.pm',
    'lib/Catalyst/Model/SMS.pm',
    't/00-load.t',
    't/01-live-test.t',
    't/02-sms-test.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author/pod-coverage.t',
    't/author/pod.t',
    't/lib/Makefile.PL',
    't/lib/TestApp.pm',
    't/lib/TestApp/Controller/Root.pm',
    't/lib/TestApp/Model/SMS.pm',
    't/lib/script/testapp_server.pl',
    't/lib/script/testapp_test.pl',
    't/release-kwalitee.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
