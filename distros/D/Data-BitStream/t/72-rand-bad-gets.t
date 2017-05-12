#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Data::BitStream;
my @encodings = qw|
              Unary Unary1 Gamma Delta Omega
              Fibonacci FibGen(3) FibGen(12) EvenRodeh Levenstein
              Golomb(10) Golomb(16) Golomb(14000)
              Rice(2) Rice(9)
              GammaGolomb(3) GammaGolomb(128) ExpGolomb(5)
              Baer(0) Baer(-2) Baer(2)
              Comma(2) Comma(6) BlockTaboo(01) BlockTaboo(10010)
              Binword(32)
              ARice(2)
            |;
            # TODO:
            #  BoldiVigna(2)
            #  StartStepStop(3-3-99) StartStop(1-0-1-0-2-12-99)

my $nloops = 20;

plan tests => $nloops * 2 * scalar @encodings;

my $s = Data::BitStream->new;
for (1 .. $nloops)
{
  $s->erase_for_write;
  my $nshorts = 16; # 16*16-bits = 256 bytes
  for (1 .. $nshorts) {
    $s->write(16, int(rand(65536)));
  }
  # write various terminators to force codes to end
  $s->write(3, 2);  # 010 ends most codes
  $s->put_string( '1' x (9*16*$nshorts+9) );  # Lots of 1s to end Rice/Golomb
  $s->write_close;

  # Pick a random position to start
  my $pos = int(rand(64));
  foreach my $code (@encodings) {
    # Set position to a little way in
    $s->rewind;  $s->skip($pos);  die "Position error" unless $s->pos == $pos;
    my $v;
    eval { $v = $s->code_get($code); };
    if ($@ eq '') {
      # The random data is decoded as a value.  Good for us.
      isnt($v, undef, "Read a value with $code");
      cmp_ok($s->pos, '>', $pos, "Good $code read at least one bit");
    } else {
      # The only error we should see is a code error, and we expect the
      # stream position to remain unchanged after the trapped read.
      like($@, qr/code error/i, "$code trapped bad read");
      is($s->pos, $pos, "Bad $code read left position unchanged");
    }
  }
}
