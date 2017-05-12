
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.07

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Akamai/Open/Client.pm',
    'lib/Akamai/Open/Debug.pm',
    'lib/Akamai/Open/Request.pm',
    'lib/Akamai/Open/Request/EdgeGridV1.pm',
    't/0001-client.t',
    't/0002-debug.t',
    't/0004-request.t',
    't/0005-edgegridv1.t',
    't/0006-signedrequest.t',
    't/0007-signedrequest-extended.t',
    't/release-no-tabs.t',
    't/release-pod-syntax.t',
    't/testdata.json'
);

notabs_ok($_) foreach @files;
done_testing;
