#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use lib qw(t/lib);
use BitStreamTest;

my @implementations = impl_list;

plan tests => scalar @implementations * 4;

foreach my $type (@implementations) {

  my $encoding = 'gamma';

  {
    my $nvals = 1000;
    my @data;
    srand(10);
    for (1 .. $nvals) {
      push @data, int(rand(1000));
    }
    my $stream = stream_encode_array($type, $encoding, @data);
    die "no stream for $encoding" unless defined $stream;
    my $string_stream = stream_encode_array('string', $encoding, @data);
    die "no string stream for $encoding" unless defined $string_stream;

    my $bits = $stream->len;
    my $str = $stream->to_string;      # text binary string
    my $raw = $stream->to_raw;         # big-endian bits
    my $store = $stream->to_store;     # whatever internal form they want

    {
       my $string_str = $string_stream->to_string;
       ok(    (length($str) == length($string_str))
           && ($str eq $string_str),
           "$type exported string matches the string implementation");
    }

    $stream->erase;

    {
      $stream->from_string($str, $bits);
      my @v = stream_decode_array($encoding, $stream);
      is_deeply( \@v, \@data, "$type export/import via string");
    }
    {
      $stream->from_raw($raw, $bits);
      my @v = stream_decode_array($encoding, $stream);
      is_deeply( \@v, \@data, "$type export/import via raw");
    }
    {
      $stream->from_store($store, $bits);
      my @v = stream_decode_array($encoding, $stream);
      is_deeply( \@v, \@data, "$type export/import via store");
    }
  }
}
