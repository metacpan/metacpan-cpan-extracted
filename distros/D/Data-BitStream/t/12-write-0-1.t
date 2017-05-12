#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use lib qw(t/lib);
use BitStreamTest;

my @implementations = impl_list;

plan tests => 2 * scalar @implementations;

foreach my $type (@implementations) {

  my $stream = new_stream($type);
  my $maxbits = $stream->maxbits;

  # write 0 with many bits
  $stream->write($maxbits*10, 0);
  # write 1 with many bits
  $stream->write($maxbits*10, 1);

  # Read them as unary
  $stream->rewind_for_read;
  my $v = $stream->get_unary;
  is($v, $maxbits*10 * 2 - 1, "$type: read unary after writing 0 and 1 with many bits");

  # Read as a string
  my $expect = ('0' x ($maxbits*10*2 - 1)) . '1';
  is($stream->to_string, $expect, "$type: read as string");
}
