#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use lib qw(t/lib);
use BitStreamTest;

my @implementations = impl_list;
my @encodings       = encoding_list;

plan tests => scalar @encodings * scalar @implementations;

foreach my $type (@implementations) {
  my $nvals = 200;
  if ($type eq 'minimalvec') { $nvals =  100; }
  elsif ($type eq 'xs')      { $nvals = 1000; }
  my @data;
  srand(52);
  push @data, int(rand(1025))  for (1 .. $nvals);

  foreach my $encoding (@encodings) {
    my $stream = stream_encode_array($type, $encoding, @data);
    BAIL_OUT("No stream of type $type") unless defined $stream;
    my @v = stream_decode_array($encoding, $stream);
    is_deeply( \@v, \@data, "$type: $encoding store $nvals random values");
  }
}
