
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
    'AUTHOR_PLEDGE',
    'CODE_OF_CONDUCT.md',
    'CONTRIBUTING',
    'Changes',
    'LICENSE',
    'MANIFEST.SKIP',
    'META.json',
    'META.yml',
    'Makefile.PL',
    'README.pod',
    'TODO',
    'bin/router-colorizer.pl',
    'dist.ini',
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
    't/08-ciena.t',
    't/90-meta-mode.t',
    't/91-junos-security-sessions.t',
    't/author-critic.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/author-test-version.t',
    't/release-changes_has_content.t',
    't/release-kwalitee.t',
    't/release-trailing-space.t'
);

notabs_ok($_) foreach @files;
done_testing;
