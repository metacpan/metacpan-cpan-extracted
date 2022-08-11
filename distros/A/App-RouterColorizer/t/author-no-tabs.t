
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
    'bin/router-colorizer.pl',
    'lib/App/RouterColorizer.pm',
    't/00-load.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-use.t',
    't/02-ip-addresses.t',
    't/03-numbers.t',
    't/04-arista.t',
    't/05-junos.t',
    't/06-vyos.t',
    't/07-cisco.t',
    't/author-critic.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/author-test-version.t',
    't/data/02-ip-addresses.input',
    't/data/02-ip-addresses.output',
    't/data/03-numbers.input',
    't/data/03-numbers.output',
    't/data/04-arista.input',
    't/data/04-arista.output',
    't/data/05-junos.input',
    't/data/05-junos.output',
    't/data/06-vyos.input',
    't/data/06-vyos.output',
    't/data/07-cisco.input',
    't/data/07-cisco.output',
    't/data/perlcriticrc',
    't/release-changes_has_content.t',
    't/release-kwalitee.t',
    't/release-trailing-space.t',
    't/release-unused-vars.t'
);

notabs_ok($_) foreach @files;
done_testing;
