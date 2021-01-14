
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Bot/IRC.pm',
    'lib/Bot/IRC/Convert.pm',
    'lib/Bot/IRC/Functions.pm',
    'lib/Bot/IRC/Greeting.pm',
    'lib/Bot/IRC/History.pm',
    'lib/Bot/IRC/Infobot.pm',
    'lib/Bot/IRC/Join.pm',
    'lib/Bot/IRC/Karma.pm',
    'lib/Bot/IRC/Math.pm',
    'lib/Bot/IRC/Ping.pm',
    'lib/Bot/IRC/Seen.pm',
    'lib/Bot/IRC/Store.pm',
    'lib/Bot/IRC/Store/SQLite.pm',
    't/00-compile.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/author-synopsis.t',
    't/bot-irc-api.t',
    't/bot-irc-run.t',
    't/convert.t',
    't/functions.t',
    't/greeting.t',
    't/history.t',
    't/infobot.t',
    't/join.t',
    't/karma.t',
    't/lib/SimpleTestPlugin.pm',
    't/lib/TestCommon.pm',
    't/math.t',
    't/ping.t',
    't/release-kwalitee.t',
    't/seen.t',
    't/store-sqlite.t',
    't/store.t'
);

notabs_ok($_) foreach @files;
done_testing;
