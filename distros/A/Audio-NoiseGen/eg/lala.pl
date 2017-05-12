#!/usr/bin/env perl

use v5.12;
use Audio::NoiseGen ':all';

init();

play( gen =>
  combine( gens => [
    segment(
      gen     => \&square,
      notes => 'A2 B2'
    ),
    segment( notes => 'F G/2 G/2 F R' ),
    segment( notes => '
      C5 D5/2 E5/2 G5 G#5 E5 G5 E5 R
      C5 D5/2 E5/2 G5 G#5 E5 G5 E5 R
      G5 F5 E5 C5 R
      G5 F5 E5 C5 R
    ' ),
  ]),
);
  
