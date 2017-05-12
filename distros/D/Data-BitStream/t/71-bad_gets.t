#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Data::BitStream;
my @encodings = qw|
              Unary Unary1 Gamma Delta Omega
              Fibonacci EvenRodeh Levenstein
              Golomb(10) Golomb(16) Golomb(14000)
              Rice(2) Rice(9)
              GammaGolomb(3) GammaGolomb(128) ExpGolomb(5)
              BoldiVigna(2) Baer(0) Baer(-2) Baer(2)
              StartStepStop(3-3-99) StartStop(1-0-1-0-2-12-99)
              Comma(2) Comma(5)
              BlockTaboo(10) BlockTaboo(101001)
              ARice(2)
            |;

plan tests =>   3*12*3 - 2*3
              + 3*5*3
              + 5*3
              + 1*3
              + scalar @encodings * 2
              + scalar @encodings * 7
              + 10*3;

my $s = Data::BitStream->new;
my $v;

foreach my $nzeros (16,48,280)
{
  # For our first set of tests, we're going to write some zeros, then try to
  # read Unary and codes using unary bases, and verify that we get the right
  # error code as well as leave the position unchanged.
  $s->erase_for_write;
  $s->write($nzeros, 0);
  $s->rewind_for_read;
  foreach my $code (qw|Unary Gamma Delta Fibonacci Rice(2) Golomb(10) GammaGolomb(3) ExpGolomb(5) ARice(2) BoldiVigna(2) Binword(32) Comma(2)|) {
    next if $code =~ /Binword/ and $nzeros > 32;
    # Set position to a little way in
    $s->rewind;  $s->skip(3);  die "Position error" unless $s->pos == 3;
    eval { $s->code_get($code); };
    like($@, qr/read off end of stream/i, "$code off $nzeros-bit stream");
    is($s->pos, 3, "$code read off $nzeros-bit stream left position unchanged");
    is($s->code_pos_is_set(), undef, "$code error position cleanup");
  }
}

foreach my $nzeros (16,48,280)
{
  # Next, do the same with 1's.
  $s->erase_for_write;
  $s->write(32, 0xFFFFFFFF) for (1 .. $nzeros/32);
  $s->write($nzeros % 32, 0xFFFFFFFF);
  $s->rewind_for_read;
  foreach my $code (qw|Unary1 Omega Levenstein Baer(-2) BlockTaboo(100)|) {
    # Set position to a little way in
    $s->rewind;  $s->skip(3);  die "Position error" unless $s->pos == 3;
    eval { $s->code_get($code); };
    if      ( ($nzeros > 32) && ($code =~ /Omega/i) ) {
      like($@, qr/code error/i, "$code off $nzeros-bit stream");
    } elsif ( ($nzeros > 32) && ($code =~ /BlockTaboo/i) ) {
      like($@, qr/(code error|read off end of stream)/i, "$code off $nzeros-bit stream");
    } else {
      like($@, qr/read off end of stream/i, "$code off $nzeros-bit stream");
    }
    is($s->pos, 3, "$code read off $nzeros-bit stream left position unchanged");
    is($s->code_pos_is_set(), undef, "$code error position cleanup");
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
    is($s->code_pos_is_set(), undef, "$code error position cleanup");
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
    is($s->code_pos_is_set(), undef, "$code error position cleanup");
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
    is($s->code_pos_is_set(), undef, "$code error position cleanup");
  }
}

{
  # Write negative and undefined values
  foreach my $code (@encodings) {
    $s->erase_for_write;
    my $v;
    eval { $v = $s->code_put($code, -5); };
    like($@, qr/value must be >= 0/i, "$code write negative value");
    is($v, undef, "Got undef for $code writing negative value");
    is($s->pos, 0, "$code writing negative value left position unchanged");
    eval { $v = $s->code_put($code, undef); };
    like($@, qr/value must be >= 0/i, "$code write undef value");
    is($v, undef, "Got undef for $code writing undef");
    is($s->pos, 0, "$code writing undef left position unchanged");
    is($s->code_pos_is_set(), undef, "$code error position cleanup");
  }
}

{
  # Write a normal unary start code, then end the stream.  Read with various
  # codes that use a unary prefix and see if it fails gracefully.
  $s->erase_for_write;
  $s->write(8, 1);
  $s->rewind_for_read;
  foreach my $code (qw|Gamma Delta Fibonacci Rice(2) Golomb(10) GammaGolomb(3) ExpGolomb(5) ARice(2) BoldiVigna(2) Binword(32)|) {
    # Set position to a little way in
    $s->rewind;  $s->skip(3);  die "Position error" unless $s->pos == 3;
    eval { $s->code_get($code); };
    like($@, qr/read off end of stream/i, "$code after partial stream");
    is($s->pos, 3, "$code after partial stream left position unchanged");
    is($s->code_pos_is_set(), undef, "$code error position cleanup");
  }
}

# TODO: off stream after base
# TODO: invalid string (XS allows 0 and anything
# TODO: EvenRodeh, StartStepStop, StartStop
# TODO: Better off-stream tests for Omega and BlockTaboo
