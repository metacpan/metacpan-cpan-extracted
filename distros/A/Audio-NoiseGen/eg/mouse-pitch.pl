#!/usr/bin/env perl

use v5.14;
use Audio::NoiseGen ':all';

init();

sub mousefreq {
  my $c = 0;
  my ($x, $y) = (0, 0);
  return sub {
    # Don't update too often
    unless($c++ % 1000) {
      ($x, $y) = split(' ', `xmousepos`);
      print "pos: $x, $y\n";
    }
    return $x;
  }
}

sub mousevol {
  my $max = shift;
  my $c = 0;
  my ($x, $y) = (0, 0);
  return sub {
    # Don't update too often
    unless($c++ % 1000) {
      ($x, $y) = split(' ', `xmousepos`);
      print "mosevol: " . ($y * (1 / $max)) . "\n";
    }
    return $y * (1 / $max);
  }
}

play( gen =>
  amp(
    amount => mousevol(800),
  # lowpass(
    # rc => mousevol(800),
    gen => sine(
      freq => mousefreq()
    )
  )
);

