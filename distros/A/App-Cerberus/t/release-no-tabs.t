
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/cerberus.pl',
    'lib/App/Cerberus.pm',
    'lib/App/Cerberus/Plugin.pm',
    'lib/App/Cerberus/Plugin/BrowserDetect.pm',
    'lib/App/Cerberus/Plugin/GeoIP.pm',
    'lib/App/Cerberus/Plugin/Throttle.pm',
    'lib/App/Cerberus/Plugin/Throttle/Memcached.pm',
    'lib/App/Cerberus/Plugin/Throttle/Memory.pm',
    'lib/App/Cerberus/Plugin/TimeZone.pm',
    't/release-eol.t',
    't/release-no-tabs.t',
    't/release-pod-syntax.t'
);

notabs_ok($_) foreach @files;
done_testing;
