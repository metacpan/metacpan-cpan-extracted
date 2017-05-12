#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Data::BitStream::XS;
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

plan tests => 3*scalar @encodings;

my @data = 0 .. 257;
my $stream1 = Data::BitStream::XS->new;
my $stream2 = Data::BitStream::XS->new;
foreach my $encoding (@encodings) {
  $stream1->erase_for_write;
  $stream1->code_put($encoding, @data);

  my $str = $stream1->to_string;
  my $len = $stream1->len;
  is ($len, length($str), "$encoding to_string length is correct");

  $stream2->from_string($str, $len);
  is ($len, $stream2->len, "$encoding from_string length is correct");

  $stream2->rewind_for_read;
  my @v = $stream2->code_get($encoding, -1);
  is_deeply( \@v, \@data, "$encoding to/from strings 0-257");
}
