#!perl -w
use strict;
use warnings;
use v5.16;
use Acme::IEnumerable;

say join ',',
  Acme::IEnumerable
    ->range(1)
    ->take(10)
    ->reverse
    ->to_perl;
