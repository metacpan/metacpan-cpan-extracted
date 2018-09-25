
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
    'bin/bp_remote_blast.pl',
    'lib/Bio/Tools/Run/RemoteBlast.pm',
    't/00-compile.t',
    't/author-mojibake.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/release-RemoteBlast.t',
    't/release-RemoteBlast_rpsblast.t'
);

notabs_ok($_) foreach @files;
done_testing;
