#!/usr/bin/perl
use strict;
use warnings;

use Test::More  tests => 1;

use Data::BitStream::XS;

# Make a big random sring
my $str = '';
my $nbits = 10_000;
for (1 .. $nbits) {
  $str .= (rand(1) < 0.5)  ?  '0'  :  '1';
}
die unless $nbits == length($str);
die if $str =~ /[^01]/;

my $stream = Data::BitStream::XS->new;
my $maxbits = $stream->maxbits;

# Insert it in chunks
{
  $stream->erase_for_write;
  my $pos = 0;
  while ($pos < $nbits) {
    my $maxput = $nbits - $pos;
    my $putlen = 1 + int(rand($maxbits * 4)); # 1-4*$maxbits
    $putlen = $maxput if $putlen > $maxput;
    $stream->put_string( substr($str, $pos, $putlen) );
    $pos += $putlen;
  }
}

# Read the whole thing as a string and verify it matches
ok( $str eq $stream->to_string, "streams match after chunked put_string");
