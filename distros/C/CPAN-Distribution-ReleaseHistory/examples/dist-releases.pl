#!/usr/bin/env perl
# ABSTRACT: Show all the releases of a given dist

use strict;
use warnings;
use utf8;

use lib 'lib';

use CPAN::Distribution::ReleaseHistory;

die "Specify a distribution name" unless my $distname = shift @ARGV;

my $rh = CPAN::Distribution::ReleaseHistory->new( distribution => $distname );
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
}

my @sorted = sort { $a <=> $b } @intervals;

sub format_delta {
  my ($delta) = @_;
  my $string = '';

  if ( $delta < 1 ) {
    return '0s';
  }
  $string = ( $delta % 60 ) . 's';
  $delta  = int( $delta / 60 );
  return $string if $delta < 1;
  $string = ( $delta % 60 ) . 'm ' . $string;
  $delta  = int( $delta / 60 );
  return $string if $delta < 1;
  $string = ( $delta % 24 ) . 'h ' . $string;
  $delta  = int( $delta / 24 );
  return $string if $delta < 1;
  return $delta . 'd ' . $string;
}

print "# -- Interval Stats\n";
printf "#min           : %s\n", format_delta( $sorted[0] );
printf "#lower quartile: %s\n", format_delta( $sorted[ int( $#sorted / 4 ) ] );
printf "#median        : %s\n", format_delta( $sorted[ int( $#sorted / 2 ) ] );
printf "#upper quartile: %s\n", format_delta( $sorted[ int( $#sorted / 4 * 3 ) ] );
printf "#max           : %s\n", format_delta( $sorted[-1] );

