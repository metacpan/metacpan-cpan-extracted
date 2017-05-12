#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use lib qw(t/lib);
use BitStreamTest;

my @implementations = impl_list;
my @encodings       = encoding_list;

plan tests => scalar @encodings * scalar @implementations;;

my @data = (0 .. 257);

foreach my $type (@implementations) {

  my $asize = 129;
  if ($type eq 'minimalvec') { $asize =   65; }
  elsif ($type eq 'xs')      { $asize = 1025; }
  my @data = (0 .. $asize);
  push @data, reverse @data;

  foreach my $encoding (@encodings) {
    my $stream = stream_encode_array($type, $encoding, @data);
    BAIL_OUT("No stream of type $type") unless defined $stream;
    my @v = stream_decode_array($encoding, $stream);
    is_deeply( \@v, \@data, "$type: $encoding store ascending/descending array");
  }
}
