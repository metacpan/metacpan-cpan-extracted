
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.06

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/yada',
    'lib/AnyEvent/Net/Curl/Const.pm',
    'lib/AnyEvent/Net/Curl/Queued.pm',
    'lib/AnyEvent/Net/Curl/Queued/Easy.pm',
    'lib/AnyEvent/Net/Curl/Queued/Multi.pm',
    'lib/AnyEvent/Net/Curl/Queued/Stats.pm',
    'lib/YADA.pm',
    'lib/YADA/Worker.pm'
);

notabs_ok($_) foreach @files;
done_testing;
