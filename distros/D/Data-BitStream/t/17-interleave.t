#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use List::Util qw(shuffle);
use lib qw(t/lib);
use BitStreamTest;

# The purpose of this test is to ensure the base implementations keep all their
# data stored in instance data, and nothing is cached shared among streams.

my $nstreams = 7;
my $nvals    = 500;

my @implementations = impl_list;
#plan tests =>  scalar @implementations * $nstreams * $nvals;
plan tests =>  scalar @implementations;

foreach my $type (@implementations) {

  srand(12);
  my @stream_data;   # array of arrays holding random integers
  my @streams;       # array of stream objects
  my @nstream;       # array of stream numbers, one per value

  # Create data and streams
  foreach my $stream_number (1 .. $nstreams) {
    foreach my $n (1 .. $nvals) {
      $stream_data[$stream_number][$n] = int(rand(1000));
      push @nstream, $stream_number;
    }
    $streams[$stream_number] = new_stream($type);
  }

  # Now insert the data into interleaved streams, random ordering
  {
    my @stream_counter;
    foreach my $sn (shuffle @nstream) {
      $stream_counter[$sn]++;
      my $v = $stream_data[$sn][$stream_counter[$sn]];
      $streams[$sn]->put_gamma( $v );
      # close each stream as it is done
      $streams[$sn]->write_close if $stream_counter[$sn] >= $nvals;
    }
  }

  # Now read the interleaved streams in another random ordering
  {
    my $success = 1;
    my @stream_counter;
    foreach my $sn (shuffle @nstream) {
      $stream_counter[$sn]++;
      # open each stream as we come to it
      $streams[$sn]->rewind if $stream_counter[$sn] == 1;
      my $v = $streams[$sn]->get_gamma();
      my $orig = $stream_data[$sn][$stream_counter[$sn]];
      #is($v, $orig, "$type interleaved gamma coding, value $stream_counter[$sn] of stream $sn/$nstreams");
      $success = 0 if $v != $orig;
    }
    ok($success, "$type: interleaved gamma coding ($nstreams streams)");
  }
}

done_testing();
