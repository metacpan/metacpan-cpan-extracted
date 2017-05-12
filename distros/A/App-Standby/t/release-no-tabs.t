
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.08

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/standby-mgm-cgi.pl',
    'bin/standby-mgm.pl',
    'bin/standby-mgm.psgi',
    'lib/App/Standby.pm',
    'lib/App/Standby/Cmd.pm',
    'lib/App/Standby/Cmd/Command.pm',
    'lib/App/Standby/Cmd/Command/bootstrap.pm',
    'lib/App/Standby/DB.pm',
    'lib/App/Standby/Frontend.pm',
    'lib/App/Standby/Group.pm',
    'lib/App/Standby/Service.pm',
    'lib/App/Standby/Service/HTTP.pm',
    'lib/App/Standby/Service/MS.pm',
    'lib/App/Standby/Service/Pingdom.pm',
    't/00-load.t',
    't/bootstrap.t',
    't/frontend.t',
    't/manifest.t',
    't/pod-coverage.t',
    't/pod.t',
    't/release-eol.t',
    't/release-no-tabs.t',
    't/release-pod-syntax.t'
);

notabs_ok($_) foreach @files;
done_testing;
