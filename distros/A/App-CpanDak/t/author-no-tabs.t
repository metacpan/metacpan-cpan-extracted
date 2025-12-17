
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
    'bin/cpandak',
    'lib/App/CpanDak.pm',
    'lib/App/CpanDak/Specials.pm',
    't/base.t',
    't/env.t',
    't/patch.t',
    't/specials.t',
    't/specials/Dak-Test.configure.env.yml',
    't/specials/test-dist.patch',
    't/test-dist/README.txt'
);

notabs_ok($_) foreach @files;
done_testing;
