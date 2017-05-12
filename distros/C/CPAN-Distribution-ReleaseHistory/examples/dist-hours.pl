#!/usr/bin/env perl
# ABSTRACT: Show hour-of-day distribution for a given dist

use strict;
use warnings;
use utf8;

use lib 'lib';

use CPAN::Distribution::ReleaseHistory;

die "Specify a distribution name" unless my $distname = shift @ARGV;

my $rh = CPAN::Distribution::ReleaseHistory->new( distribution => $distname );
my $iterator = $rh->release_iterator;

my %buckets = ( map { $_ => 0 } 0 .. 23 );

sub record_timestamp {
  my ($ts)     = @_;
  my (@fields) = gmtime $ts;
  $buckets{ $fields[2] }++;
}
while ( my $release = $iterator->next_release ) {
  record_timestamp( $release->timestamp );
  printf "%s\t%s\n", $release->timestamp, $release->path;
}
my $max = [ sort { $a <=> $b } values %buckets ]->[-1];
my $scale = 1;
$scale = 40 / $max if $max > 40;
for my $key ( sort { $a <=> $b } keys %buckets ) {
  printf "%s : %s\n", $key, "#" x ( int( $buckets{$key} * $scale ) );
}

