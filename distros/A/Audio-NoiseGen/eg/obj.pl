#!/usr/bin/env perl

use strict;
use Audio::NoiseGen ':all';

Audio::NoiseGen::init();
# play(segment_gen('C'));

sub noisify {
  my $g = shift;
  my $width = shift || 0.01;
  return sub {
    my $sample = $g->();
    return undef if ! defined $sample;
    $sample += (rand $width) - ($width / 2);
  }
}

# my $cnote = Audio::NoiseGen::segment_gen('C');
# Audio::NoiseGen::play($cnote);
(
  G('C D E') * G('D E F')
+ G('C D E') * G('D E F')
+ G('D E F') * G('E F G')
)
->mplay;


