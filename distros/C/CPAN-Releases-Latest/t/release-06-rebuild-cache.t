#!perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print "1..0 # SKIP these tests are for release candidate testing\n";
    exit
  }
}

#
# xt/release/06-rebuild-cache.t
#
# This tests the case where
#   1. You've got an existing cache
#   2. It's more recent than the max_age you specified
#   3. The format revision is earlier than that currently supported
# In this case if you start an iterator, the first time you get
# something the cache should be rebuilt.
#

use strict;
use warnings;
use Test::More 0.88 tests => 4;
use CPAN::Releases::Latest;
use File::Copy qw/ copy /;

my $CACHE_PATH = 't/06-cache-file.txt';
my $latest;
my $iterator;
my $release;

copy('t/data/04-earlier-revision.txt' => $CACHE_PATH)
    || BAIL_OUT("failed to set up initial cache");

ok(1, "Set up cache file with an earlier format revision number");

$latest = CPAN::Releases::Latest->new(
              cache_path => $CACHE_PATH,
              max_age    => '10 years',
          );

ok(defined($latest), "instantiate CPAN::Releases::Latest");

$iterator = $latest->release_iterator;

ok(defined($latest), "create iterator");

while ($release = $iterator->next_release) {
    last if $release->distname eq 'Module-Path';
}

ok(defined($release) && $release->distinfo->cpanid eq 'NEILB',
   "If we rebuilt the cache, then we should find dist 'Module-Path'");

unlink($CACHE_PATH);
