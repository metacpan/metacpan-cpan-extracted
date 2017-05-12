#!/usr/bin/perl
use strict;
use warnings;
#use FindBin;  use lib "$FindBin::Bin/../lib";
use Data::BitStream::XS qw(code_is_supported code_is_universal);
use Test::More;

my @codes = qw|
  Gamma
  Delta
  Omega
  EvenRodeh
  Levenstein
  Fibonacci
  Unary
  Unary1
  Baer(0)
  Baer(-1)
  Baer(-2)
  Baer(-8)
  Baer(1)
  Baer(2)
  Baer(8)
  Golomb(1)
  Golomb(2)
  Golomb(3)
  Golomb(177)
  Rice(0)
  Rice(1)
  Rice(2)
  Rice(7)
  Golomb(177)
  GammaGolomb(1)
  GammaGolomb(2)
  GammaGolomb(3)
  GammaGolomb(16)
  ExpGolomb(1)
  ExpGolomb(2)
  ExpGolomb(3)
  ExpGolomb(16)
  StartStop(0-0-2-3-9)
  StartStop(3-2-9)
  StartStepStop(3-2-13)
  Comma(2)
  Comma(3)
  BlockTaboo(00)
  BlockTaboo(00110)
  BinWord(15)
|;

plan tests => 3 * scalar @codes;

foreach my $code (@codes) {
  my $issupported = code_is_supported($code);
  my $isuniversal = code_is_universal($code);
  ok($issupported, "$code is supported");
  ok($isuniversal || !$isuniversal, "$code is or is not universal");
}

my $stream = Data::BitStream::XS->new;
my $mod = 8000;

foreach my $code (@codes) {
  my $v = unpack("%32C*", $code) % $mod;
  #print "putting $v with $code\n";
  $stream->code_put($code, $v);
}
$stream->rewind_for_read;
foreach my $code (@codes) {
  my $expect = unpack("%32C*", $code) % $mod;
  my $v = $stream->code_get($code);
  is($v,$expect, "get with $code");
}
