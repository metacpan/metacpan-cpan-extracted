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

plan tests => 46 + (1 * scalar @encodings);

my $s = Data::BitStream::XS->new;
my $v;

{
  # For our first set of tests, we're going to write some zeros, then try to
  # read Unary and codes using unary bases, and verify that we get the right
  # error code as well as leave the position unchanged.
  $s->erase_for_write;
  $s->write(16, 0);
  $s->rewind_for_read;
  foreach my $code (qw|Unary Gamma Delta Fibonacci Rice(2) Golomb(10) GammaGolomb(3) ExpGolomb(5) ARice(2) Binword(32) Comma(2) BlockTaboo(11)|) {
    # Set position to a little way in
    $s->rewind;  $s->skip(3);  die "Position error" unless $s->pos == 3;
    eval { $s->code_get($code); };
    like($@, qr/read off end of stream/i, "$code off stream");
    is($s->pos, 3, "Bad $code read left position unchanged");
    $s->rewind;  $s->skip(3); # put position back
  }
}

{
  # Next, do the same with 1's.
  $s->erase_for_write;
  $s->write(16, 0xFFFFFFFF);
  $s->rewind_for_read;
  foreach my $code (qw|Unary1 Omega Levenstein Baer(-2) BlockTaboo(000)|) {
    # Set position to a little way in
    $s->rewind;  $s->skip(3);  die "Position error" unless $s->pos == 3;
    eval { $s->code_get($code); };
    like($@, qr/read off end of stream/i, "$code off stream");
    is($s->pos, 3, "Bad $code read left position unchanged");
  }
}

{
  # Now we'll write a bogus unary base and see how the codes handle getting
  # invalid bases.  This is a lot harder to handle.
  $s->erase_for_write;
  $s->write(7, 0xFFFFFFFF);
  $s->put_unary(259);
  $s->write(32, 0xFFFFFFFF);
  $s->rewind_for_read;
  foreach my $code (qw|Gamma Delta GammaGolomb(3) ExpGolomb(5) ARice(2)|) {
    # Set position to a little way in
    $s->rewind;  $s->skip(7);  die "Position error" unless $s->pos == 7;
    eval { $s->code_get($code); };
    like($@, qr/code error/i, "$code bad base");
    is($s->pos, 7, "Bad $code read left position unchanged");
  }
}

{
  # Same but using bogus gamma base.
  $s->erase_for_write;
  $s->write(7, 0xFFFFFFFF);
  $s->put_gamma(259);
  $s->write(32, 0xFFFFFFFF);
  $s->rewind_for_read;
  foreach my $code (qw|Delta|) {
    # Set position to a little way in
    $s->rewind;  $s->skip(7);  die "Position error" unless $s->pos == 7;
    eval { $s->code_get($code); };
    like($@, qr/code error/i, "$code bad base");
    is($s->pos, 7, "Bad $code read left position unchanged");
  }
}

{
  # Something a little different: read from an empty stream.
  $s->erase_for_write;
  $s->rewind_for_read;
  foreach my $code (@encodings) {
    $s->rewind;
    my $v = $s->code_get($code);
    is($v, undef, "Empty stream returned undef for $code");
  }
}

# TODO: off stream after base
