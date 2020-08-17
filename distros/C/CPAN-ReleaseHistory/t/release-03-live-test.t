#! perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}


use strict;
use warnings;

use Test::More 0.88 tests => 3;
use CPAN::ReleaseHistory;

my $cache_path = 't/live-cache.txt.gz';
my $dist_name  = 'Chatbot-Eliza';
my $expected = <<'END_EXPECTED';
0.31:JNOLAN:1997-12-06
0.32:JNOLAN:1997-12-13
0.40:JNOLAN:1998-07-25
0.91:JNOLAN:1999-04-08
0.93:JNOLAN:1999-06-04
0.94:JNOLAN:1999-07-08
0.95:JNOLAN:1999-07-09
0.96:JNOLAN:1999-10-25
0.97:JNOLAN:1999-10-31
1.01:JNOLAN:2003-01-17
1.02:JNOLAN:2003-01-21
1.04:JNOLAN:2003-01-24
1.04_01:NEILB:2014-04-05
1.05:NEILB:2014-04-17
END_EXPECTED

my $history  = CPAN::ReleaseHistory->new(cache_path => $cache_path, max_age => '1 second')
               || BAIL_OUT("Failed to create CPAN::ReleaseHistory instance");

my $iterator = $history->release_iterator(well_formed => 1)
               || BAIL_OUT("Failed to create release iterator");

my $result   = '';

my $count = 0;
while (my $release = $iterator->next_release) {
    next unless $release->distinfo->dist eq $dist_name;
    my @ts = gmtime($release->timestamp);
    $result .= sprintf("%s:%s:%4d-%.2d-%.2d\n",
                       $release->distinfo->version,
                       $release->distinfo->cpanid,
                       $ts[5]+1900,
                       $ts[4]+1,
                       $ts[3],
                       );
    ++$count;
    last if $count == 14;
}

is($result, $expected, "check first 14 releases of $dist_name match expected");
ok(unlink($cache_path), "remove the test cache that we created");
ok(! -f $cache_path, "test cache file should no longer be there");
