#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Data::BitStream::XS;

plan tests => 3;

{
  my $stream = Data::BitStream::XS->new;
  my $encoding = 'gamma';

  {
    my $nvals = 1000;
    my @data;
    srand(10);
    for (1 .. $nvals) {
      push @data, int(rand(1000));
    }
    $stream->erase_for_write;
    $stream->code_put($encoding, @data);

    my $bits  = $stream->len;
    my $str   = $stream->to_string;      # text binary string
    my $raw   = $stream->to_raw;         # big-endian bits
    my $store = $stream->to_store;     # whatever internal form they want

    $stream->erase;
    $stream->from_string($str, $bits);
    {
      $stream->rewind_for_read;
      my @v = $stream->code_get($encoding, -1);
      is_deeply( \@v, \@data, "export/import via string");
    }
    $stream->from_raw($raw, $bits);
    {
      $stream->rewind_for_read;
      my @v = $stream->code_get($encoding, -1);
      is_deeply( \@v, \@data, "export/import via raw");
    }
    $stream->from_store($store, $bits);
    {
      $stream->rewind_for_read;
      my @v = $stream->code_get($encoding, -1);
      is_deeply( \@v, \@data, "export/import via store");
    }
  }
}
