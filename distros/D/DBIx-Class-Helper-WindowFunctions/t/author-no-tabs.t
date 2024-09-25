
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
    'lib/DBIx/Class/Helper/WindowFunctions.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-simple.t',
    't/author-clean-namespaces.t',
    't/author-critic.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-linkcheck.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/data/001-partition.dd',
    't/data/002-order.dd',
    't/data/003-partition-order.dd',
    't/data/004-partition-order.dd',
    't/data/005-filter.dd',
    't/data/006-filter-only.dd',
    't/data/007-count-constant-filter.dd',
    't/lib/Test/Schema.pm',
    't/lib/Test/Schema/Result/Artist.pm',
    't/lib/Test/Schema/Result/CD.pm',
    't/lib/Test/Schema/ResultSet/Artist.pm',
    't/lib/Test/WindowFunctions.pm',
    't/lib/Test/WindowFunctions/Role.pm',
    't/release-check-manifest.t',
    't/release-fixme.t',
    't/release-kwalitee.t',
    't/release-trailing-space.t'
);

notabs_ok($_) foreach @files;
done_testing;
