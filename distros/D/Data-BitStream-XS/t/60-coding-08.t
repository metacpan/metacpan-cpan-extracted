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

my @fibs = (0,1,1);
{
  my ($v2, $v1) = ( $fibs[-2], $fibs[-1] );
  while ($fibs[-1] < ~0) {
    ($v2, $v1) = ($v1, $v2+$v1);
    push(@fibs, $v1);
  }
}

foreach my $encoding (@encodings) {
  my $stream = Data::BitStream::XS->new;

  my $nfibs = (!code_is_universal($encoding)) ? 30
                                              : ($stream->maxbits < 64)  ?  47
                                                                         :  80;
  # Perl 5.6.x 64-bit is problematic
  $nfibs = 73 if ($] < 5.008) && ($nfibs > 73);

  my @data = @fibs;
  $#data = $nfibs;
  push @data, reverse @data;

  $stream->code_put($encoding, @data);
  $stream->rewind_for_read;
  my @v = $stream->code_get($encoding, -1);
  is_deeply( \@v, \@data, "encoded F[0]-F[$nfibs]-F[0] using $encoding");
}
