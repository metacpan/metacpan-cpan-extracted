#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use lib qw(t/lib);
use BitStreamTest;

my @implementations = impl_list;

plan tests => scalar @implementations;

srand(8177);
foreach my $type (@implementations) {

  my $stream = new_stream($type);
  my $maxbits = $stream->maxbits;


  # first make a big random string
  my $str = '';
  my $nbits = 10000;
  for (1 .. $nbits) {
    $str .= (rand(1) < 0.5)  ?  '0'  :  '1';
  }
  die unless $nbits == length($str);
  die if $str =~ /[^01]/;


  # cycle through offsets and sizes
if (0) {
  foreach my $offset (0 .. 65) {
    foreach my $size (1 .. 65) {
      $stream->erase_for_write;
      $stream->put_string(substr($str, 0, $offset));
      die unless $stream->len == $offset;
      $stream->put_string(substr($str, $offset, $size));
      die unless $stream->len == $offset+$size;
      my $rstr = $stream->to_string;
      is($rstr, substr($str, 0, $offset+$size), "$type: offset $offset, size $size");
    }
  }
}

  # Insert the string in chunks
  $stream->erase_for_write;
  my $pos = 0;
  while ($pos < $nbits) {
    my $maxput = $nbits - $pos;
    my $putlen = 1 + int(rand($maxbits * 4)); # 1-4*$maxbits
    $putlen = $maxput if $putlen > $maxput;
    $stream->put_string( substr($str, $pos, $putlen) );
    $pos += $putlen;
  }

  # Now read the resulting stream and see if it matches.
  ok( $str eq $stream->to_string, "$type streams match after put_string");
}
done_testing();
