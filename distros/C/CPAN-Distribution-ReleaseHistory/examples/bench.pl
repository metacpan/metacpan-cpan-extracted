#!/usr/bin/env perl
# FILENAME: bench.pl
# CREATED: 06/12/14 21:33:15 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Benchmark sort + scroll_size effect

use strict;
use warnings;
use utf8;

use lib 'lib';
use Time::HiRes qw( gettimeofday tv_interval );
use CPAN::Distribution::ReleaseHistory;

my @sizes = ( 5, 10, 20, 50, 100 );
my @sorts = ( 'desc', 'undef' );

for my $size (@sizes) {
  for my $sort_m (@sorts) {
    my $sort_v = $sort_m;
    $sort_v = undef if defined $sort_v and q[undef] eq $sort_v;
    my $name = $size . ' ' . $sort_m;
    my $total_items;
    my $total_time;

    for my $run ( 0 .. 2 ) {
      my $object = CPAN::Distribution::ReleaseHistory->new(
        scroll_size  => $size,
        sort         => $sort_v,
        distribution => q[Dist-Zilla],
      );
      my $start     = [gettimeofday];
      my $resultset = $object->release_iterator;
      while ( my $item = $resultset->next_release ) {
        $total_items++;
      }
      my $end = [gettimeofday];
      $total_time += tv_interval( $start, $end );
    }
    printf "%10s average %2.5f /each %8.3f items/sec\n", $name, $total_time / $total_items, $total_items / $total_time;

  }
}

