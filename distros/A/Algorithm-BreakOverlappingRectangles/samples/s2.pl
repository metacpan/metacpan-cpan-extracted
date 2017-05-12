#!/usr/bin/perl

use strict;
use warnings;

use Algorithm::BreakOverlappingRectangles;

my $bor = Algorithm::BreakOverlappingRectangles->new;

                     # id => X0, Y0, X1, Y1
$bor->add_rectangle( 0,  4,  7, 10, 'A');
$bor->add_rectangle( 3,  2,  9,  6, 'B');
$bor->add_rectangle( 5,  0, 11,  8, 'C');

  # that's:
  #
  #   Y
  #   ^
  #   |
  #  11
  #  10 +------+
  #   9 |      |
  #   8 |  A +-+---+
  #   7 |    |     |
  #   6 |  +-+---+ |
  #   5 |  |     | |
  #   4 +--+  B  | |
  #   3    |     | |
  #   2    +-+---+ |
  #   1      |  C  |
  #   0      +-----+
  #   |
  #   +-01234567891111--> X
  #               0123
  #

$bor->dump;

  # prints:
  #
  # [0 4 3 10 | A]
  # [3 4 5 6 | A B]
  # [3 6 5 8 | A]
  # [7 2 9 4 | B C]
  # [3 2 5 4 | B]
  # [5 4 7 6 | A B C]
  # [3 8 7 10 | A]
  # [5 6 7 8 | A C]
  # [7 4 9 6 | B C]
  # [5 2 7 4 | B C]
  # [9 0 11 4 | C]
  # [9 4 11 6 | C]
  # [7 6 11 8 | C]
  # [5 0 9 2 | C]
  #
  # that's:
  #
  #   Y
  #   ^
  #   |
  #  11
  #  10 +----+-+
  #   9 |    | |
  #   8 |    +-+---+
  #   7 |    | |   |
  #   6 +--+-+-+-+-+
  #   5 |  | | | | |
  #   4 +--+-+-+ | |
  #   3    | | | | |
  #   2    +-+-+-+-+
  #   1      |     |
  #   0      +-----+
  #   |
  #   +-01234567891111--> X
  #               0123
  #

