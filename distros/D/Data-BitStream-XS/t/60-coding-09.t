#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Data::BitStream::XS qw(code_is_universal);
my @encodings = qw|
              Unary Unary1 Gamma Delta Omega
              Fibonacci FibGen(3) EvenRodeh Levenstein
              Golomb(10) Golomb(16) Golomb(14000)
              Rice(2) Rice(9)
              GammaGolomb(3) GammaGolomb(128) ExpGolomb(5)
              BoldiVigna(2) Baer(0) Baer(-2) Baer(2)
              StartStepStop(3-3-99) StartStop(1-0-1-0-2-12-99)
              Comma(2) Comma(3)
              BlockTaboo(11) BlockTaboo(0000)
              ARice(2)
            |;

plan tests => scalar @encodings;

foreach my $encoding (@encodings) {
  my $stream = Data::BitStream::XS->new;

  my $maxbits = 16;
  my $maxpat = 0xFFFF;
  if (code_is_universal($encoding)) {
    $maxbits = $stream->maxbits;
    $maxpat = ~0;
  }
  my @data;
  # Encode patterns up to 2^(maxbits-1)
  foreach my $bits (1 .. $maxbits-1) {
    my $maxval = $maxpat >> ($maxbits - $bits);
    # maxvals separated by binary '10001' and '0'
    push @data, $maxval, 17, $maxval, 0, $maxval;
  }

  $stream->code_put($encoding, @data);
  $stream->rewind_for_read;
  my @v = $stream->code_get($encoding, -1);
  is_deeply( \@v, \@data, "encoded bit patterns using $encoding");
}
