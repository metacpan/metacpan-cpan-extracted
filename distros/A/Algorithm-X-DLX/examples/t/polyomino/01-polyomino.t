#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

BEGIN {my $p = $0; $p=~ s|/[^/]+$||; unshift @INC, "$p/../../polyomino/" }
use Polyomino;
use Shape;
BEGIN { shift @INC }

subtest 'bad shape' => sub {
  plan tests => 1;
  dies_ok { Shape->new([[], [1]]) } 'width mismatch';
};

subtest 'shape rotations' => sub {
  plan tests => 6;
  is_deeply( [Shape->new()], [Shape->new()->rotations()], 'symmetry');

  is_deeply( [ Shape->new([[1]]) ], [Shape->new([[1]])->rotations()], 'symmetry');

  is_deeply( [ Shape->new([[1, 1]]), Shape->new([[1], [1]]) ], [Shape->new([[1, 1]])->rotations()], '2 placements');

  is_deeply( [ Shape->new([[1], [1]]), Shape->new([[1, 1]]) ], [Shape->new([[1], [1]])->rotations()], '2 placements');

  is_deeply( [
    Shape->new([
      [0, 1],
      [1, 1]]),
    Shape->new([
      [1, 0],
      [1, 1]]),
    Shape->new([
      [1, 1],
      [1, 0]]),
    Shape->new([
      [1, 1],
      [0, 1]])
  ], [
    Shape->new([
      [0, 1],
      [1, 1]])->rotations()
  ], '4 placements');

  is_deeply( [
    Shape->new([
      [0, 1],
      [1, 1],
      [1, 0]]),
    Shape->new([
      [1, 1, 0],
      [0, 1, 1]])
  ], [
    Shape->new([
      [0, 1],
      [1, 1],
      [1, 0]])->rotations()
  ], '4 placements');
};

subtest 'shape reflections' => sub {
  plan tests => 2;
  is_deeply( [
    Shape->new([
      [0, 1],
      [1, 1]])
  ], [
    Shape->new([
      [0, 1],
      [1, 1]])->reflections()
  ], '1 reflection');

  is_deeply( [
    Shape->new([
      [0, 1],
      [1, 1],
      [1, 0]]),
    Shape->new([
      [1,0],
      [1, 1],
      [0,1]])
  ], [
    Shape->new([
      [0, 1],
      [1, 1],
      [1, 0]])->reflections()
  ], '1 reflection');
};

subtest 'shape variations' => sub {
  plan tests => 1;

  is_deeply( [
    Shape->new([
      [0, 1, 0],
      [1, 1, 1],
      [1, 0, 0]]),
    Shape->new([
      [1, 1, 0],
      [0, 1, 1],
      [0, 1, 0]]),
    Shape->new([
      [0, 0, 1],
      [1, 1, 1],
      [0, 1, 0]]),
    Shape->new([
      [0, 1, 0],
      [1, 1, 0],
      [0, 1, 1]]),
    Shape->new([
      [0, 1, 0],
      [1, 1, 1],
      [0, 0, 1]]),
    Shape->new([
      [0, 1, 0],
      [0, 1, 1],
      [1, 1, 0]]),
    Shape->new([
      [1, 0, 0],
      [1, 1, 1],
      [0, 1, 0]]),
    Shape->new([
      [0, 1, 1],
      [1, 1, 0],
      [0, 1, 0]]),
  ], [
    Shape->new([
      [0, 1, 0],
      [1, 1, 1],
      [1, 0, 0]])->variations()
  ], '8 variations');
};

done_testing();

