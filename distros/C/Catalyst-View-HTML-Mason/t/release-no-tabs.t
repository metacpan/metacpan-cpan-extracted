
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
    'lib/Catalyst/Helper/View/HTML/Mason.pm',
    'lib/Catalyst/View/HTML/Mason.pm',
    't/basic.t',
    't/encoding.t',
    't/exceptions.t',
    't/globals.t',
    't/helper.t',
    't/lib/TestApp.pm',
    't/lib/TestApp/Controller/Root.pm',
    't/lib/TestApp/View/Global.pm',
    't/lib/TestApp/View/Mason.pm',
    't/lib/TestApp/View/PathClass.pm',
    't/lib/TestApp/root/enc/utf8',
    't/lib/TestApp/root/globals',
    't/lib/TestApp/root/index',
    't/lib/TestApp/root/xpackage_globals',
    't/lib/TestAppEnc.pm',
    't/lib/TestAppEnc/Controller/Root.pm',
    't/lib/TestAppEnc/View/Mason.pm',
    't/lib/TestAppEnc/root/enc/utf8',
    't/lib/TestAppEnc/root/index',
    't/lib/TestAppErrors.pm',
    't/lib/TestAppErrors/Controller/Root.pm',
    't/lib/TestAppErrors/View/Mason.pm',
    't/lib/TestAppErrors/View/PathClass.pm',
    't/lib/TestAppErrors/root/index',
    't/lib/TestAppGlobals.pm',
    't/lib/TestAppGlobals/Controller/Root.pm',
    't/lib/TestAppGlobals/View/Global.pm',
    't/lib/TestAppGlobals/View/Mason.pm',
    't/lib/TestAppGlobals/View/PathClass.pm',
    't/lib/TestAppGlobals/root/enc/utf8',
    't/lib/TestAppGlobals/root/globals',
    't/lib/TestAppGlobals/root/index',
    't/lib/TestAppGlobals/root/xpackage_globals',
    't/release-eol.t',
    't/release-no-tabs.t',
    't/release-pod-coverage.t',
    't/release-pod-syntax.t',
    't/root/heart',
    't/utf8.t'
);

notabs_ok($_) foreach @files;
done_testing;
