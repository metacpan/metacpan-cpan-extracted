#! perl

use strict;
use warnings;
use CPAN::Releases::Latest;
use Test::More 0.88 tests => 1;

my $PATH   = 't/data/mini-releases.txt';
my $latest = CPAN::Releases::Latest->new(path => $PATH)
             || BAIL_OUT("Failed to instantiate CPAN::Releases::Latest");
my $iterator = $latest->distribution_iterator();
my $expected = <<'END_EXPECTED';
ack|2.12|2.13_06
Grades|0.16|
Graph|0.96|0.96_01
Graphics-Magick-Object||0.01_01
Gruntmaster-Daemon||5999.000_003
END_EXPECTED

my $result   = '';

while (my $dist = $iterator->next_distribution) {
    $result .= sprintf("%s|%s|%s\n",
                       $dist->distname,
                       defined($dist->release)
                           ? $dist->release->distinfo->version
                           : '',
                       defined($dist->developer_release)
                           ? $dist->developer_release->distinfo->version
                           : ''
                      );
}
is($result, $expected,
   "iterating over dists should result in 5 dists in the expected order");
