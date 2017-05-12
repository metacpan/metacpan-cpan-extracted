#!/usr/bin/env perl
# ABSTRACT: Show the latest release of a given dist.

use strict;
use warnings;
use utf8;

use lib 'lib';

use CPAN::Distribution::ReleaseHistory;

die "Specify a distribution name" unless my $distname = shift @ARGV;

my $rh = CPAN::Distribution::ReleaseHistory->new( distribution => $distname, scroll_size => 1 );

my $iterator = $rh->release_iterator;
my $last;
my @intervals;
while ( my $release = $iterator->next_release ) {
  my $delta = '';
  if ($last) {
    $delta = $last - $release->timestamp;
    push @intervals, $delta;
  }
  $last = $release->timestamp;
  printf "%s\t%s\n", $release->timestamp, $release->path;
  last;
}
