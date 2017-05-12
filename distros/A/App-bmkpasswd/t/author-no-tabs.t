
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print "1..0 # SKIP these tests are for testing by the author\n";
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/bmkpasswd',
    'lib/App/bmkpasswd.pm',
    'lib/Crypt/Bcrypt/Easy.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/00_cmp.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/bcrypt_easy.t',
    't/cmd.t',
    't/mkpasswd.t',
    't/release-cpan-changes.t',
    't/release-dist-manifest.t',
    't/release-pod-linkcheck.t',
    't/release-unused-vars.t',
    't/warnings.t'
);

notabs_ok($_) foreach @files;
done_testing;
