
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
    'bin/provis',
    'lib/App/Provision/Chameleon5.pm',
    'lib/App/Provision/Cpanm.pm',
    'lib/App/Provision/Cpanmupdate.pm',
    'lib/App/Provision/Cpanupdate.pm',
    'lib/App/Provision/Curl.pm',
    'lib/App/Provision/Foundation.pm',
    'lib/App/Provision/Git.pm',
    'lib/App/Provision/Homebrew.pm',
    'lib/App/Provision/Mysql.pm',
    'lib/App/Provision/Perlbrew.pm',
    'lib/App/Provision/Repoupdate.pm',
    'lib/App/Provision/Sequelpro.pm',
    'lib/App/Provision/Sourcetree.pm',
    'lib/App/Provision/Ssh.pm',
    'lib/App/Provision/Tiny.pm',
    'lib/App/Provision/Wget.pm',
    't/00-compile.t',
    't/00-load.t',
    't/01-methods.t',
    't/author-pod-spell.t',
    't/release-eol.t',
    't/release-no-tabs.t',
    't/release-pod-syntax.t'
);

notabs_ok($_) foreach @files;
done_testing;
