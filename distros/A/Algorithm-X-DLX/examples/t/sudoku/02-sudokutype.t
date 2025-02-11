#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

BEGIN {my $p = $0; $p=~ s|/[^/]+$||; unshift @INC, "$p/../../sudoku/" }
use SudokuType;
BEGIN { shift @INC }

subtest 'creator default' => sub {
  plan tests => 2;
	my $type = SudokuType->new();
	is(9,  $type->n(), 'vanilla n');
	is(81, $type->size(), 'vanilla size');
};

subtest 'creator nxn region' => sub {
  plan tests => 12;
	is(1,  SudokuType->new(1)->n(), '1x1 field width');
	is(1,  SudokuType->new(1)->size(), '1x1 field size');
	is(4,  SudokuType->new(4)->n(), '4x4 fields width');
	is(16,  SudokuType->new(4)->size(), '4x4 fields size');
	is(9,  SudokuType->new(9)->n(), '9x9 fields width');
	is(81,  SudokuType->new(9)->size(), '9x9 fields size');
	is(16,  SudokuType->new(16)->n(), '16x16 fields width');
	is(256,  SudokuType->new(16)->size(), '16x16 fields size');

	throws_ok { SudokuType->new(0) }    qr/Sudoku must have non-zero size/i, 'invalid size param';
	throws_ok { SudokuType->new(3) }    qr/Not a square/i, 'invalid size param';
	throws_ok { SudokuType->new(5) }    qr/Not a square/i, 'invalid size param';
	throws_ok { SudokuType->new(8) }    qr/Not a square/i, 'invalid size param';
};

subtest 'creator nxm region' => sub {
  plan tests => 9;
	throws_ok { SudokuType->new(0, 5) }    qr/Sudoku must have non-zero/i, 'invalid width param';
	throws_ok { SudokuType->new(5, 0) }    qr/Sudoku must have non-zero/i, 'invalid height param';

	is(1,  SudokuType->new(1, 1)->n(), '1x1 field width');
	is(2,  SudokuType->new(1, 2)->n(), '1x1 field size');
	is(2,  SudokuType->new(2, 1)->n(), '4x4 fields width');
	is(9,  SudokuType->new(1, 9)->n(), '4x4 fields size');

	is(6,  SudokuType->new(2, 3)->n(), '9x9 fields width');
	is(8,  SudokuType->new(2, 4)->n(), '9x9 fields size');
	is(10,  SudokuType->new(2, 5)->n(), '16x16 fields width');
};

subtest 'creator custom region' => sub {
  plan tests => 10;
	throws_ok { SudokuType->new([]) }    qr/Sudoku must have non-zero/i, 'not a square';
	throws_ok { SudokuType->new([0, 1]) }    qr/Not a square/i, 'not a square';

	throws_ok { SudokuType->new([0, 0, 0, 1]) }    qr/Region has wrong size/i, 'invalid region';
	throws_ok { SudokuType->new([0, 0, 1, 2]) }    qr/Too many regions/i, 'invalid region';

	lives_ok { SudokuType->new([0]) } 'valid type';
	lives_ok { SudokuType->new([1]) } 'valid type';
	lives_ok { SudokuType->new([999]) } 'valid type';
	lives_ok { SudokuType->new([0, 0, 1, 1]) } 'valid type';
	lives_ok { SudokuType->new([0, 1, 1, 0]) } 'valid type';

	is_deeply(SudokuType->new([0, 0, 1, 1]),  SudokuType->new([6, 6, 2, 2]), 'same custom type');
};

subtest 'guess type nxn regions' => sub {
  plan tests => 7;
	throws_ok { SudokuType::guess(join '',
    "....",
    "....",
    "....",
    "..."
  ) } qr/Not a square/i, 'corrupt lines';
	throws_ok { SudokuType::guess(join '',
    "....",
    "....",
    "....",
    "....."
  ) } qr/Not a square/i, 'corrupt lines';
	is_deeply(SudokuType->new(1),  SudokuType::guess(join '',
    "+-+\n",
    "|.|\n",
    "+-+\n"
  ), 'same custom type');
	is_deeply(SudokuType->new(4),  SudokuType::guess(join '',
    "....",
    "....",
    "....",
    "....",
  ), 'same custom type');
	is_deeply(SudokuType->new(4),  SudokuType::guess(join '',
    ". .|..\n",
    ". .|..\n",
    " +-+--\n",
    ".|.|..\n",
    "-+ |  \n",
    ". .|..\n"
  ), 'same custom type');
	is_deeply(SudokuType->new(4),  SudokuType::guess(join '',
    "..|..\n",
    "..|..\n",
    "..|..\n",
    "--+--\n",
    "..|..\n"
  ), 'same custom type');
	is_deeply(SudokuType->new(4),  SudokuType::guess(join '',
    ".1|..\n",
    "..|2.\n",
    "-----\n",
    "z.|..\n",
    ".a|..\n"
  ), 'same custom type');
};

subtest 'guess type nxm regions' => sub {
  plan tests => 6;
	is_deeply(SudokuType->new(4, 1),  SudokuType::guess(join '',
    "....\n",
    "----\n",
    "....\n",
    "----\n",
    "....\n",
    "----\n",
    "....\n"
  ), 'same custom type');
	is_deeply(SudokuType->new(1, 4),  SudokuType::guess(join '',
    ".|.|.|.\n",
    ".|.|.|.\n",
    ".|.|.|.\n",
    ".|.|.|.\n"
  ), 'same custom type');
	is_deeply(SudokuType->new(3, 2),  SudokuType::guess(join '',
    "|...|...|\n",
    "|...|...|\n",
    "|-------|\n",
    "|...|...|\n",
    "|...|...|\n",
    "|-------|\n",
    "|...|...|\n",
    "|...|...|\n"
  ), 'same custom type');
	is_deeply(SudokuType->new(3, 2),  SudokuType::guess(join '',
    "|...|...|\n",
    "|...|...|\n",
    "\n",
    "|...|...|\n",
    "|...|...|\n",
    "\n",
    "|...|...|\n",
    "|...|...|\n"
  ), 'same custom type');
	is_deeply(SudokuType->new(3, 2),  SudokuType::guess(join '',
    "...|......|...\n\n",
    "...|......|...\n\n",
    "...|......|..."
  ), 'same custom type');
	is_deeply(SudokuType->new(3, 2),  SudokuType::guess(join '',
    "|. ..|...|\n",
    "|. ..|...|\n",
    "----------\n",
    "|. ..|...|\n",
    "|. ..|...|\n",
    "----------\n",
    "|. ..|...|\n",
    "|    |   |\n",
    "|. ..|...|\n"
  ), 'same custom type');
};

subtest 'guess arbitrary regions' => sub {
  plan tests => 5;
	is_deeply(SudokuType->new([
    0, 0, 1, 1, 1, 1, 2,
    0, 0, 0, 1, 1, 1, 2,
    3, 0, 0, 4, 4, 2, 2,
    3, 3, 4, 4, 4, 2, 2,
    3, 3, 4, 4, 5, 5, 2,
    3, 6, 6, 6, 5, 5, 5,
    3, 6, 6, 6, 6, 5, 5,
  ]), SudokuType::guess(join '',
    "+---+-------+-+\n",
    "|. .|. . . .|.|\n",
    "|   +-+     | |\n",
    "|. . .|. . .|.|\n",
    "+-+   +---+-+ |\n",
    "|.|. .|. .|. .|\n",
    "| +-+-+   |   |\n",
    "|. .|. . .|. .|\n",
    "|   |   +-+-+ |\n",
    "|. .|. .|. .|.|\n",
    "| +-+---+   +-+\n",
    "|.|. . .|. . .|\n",
    "| |     +-+   |\n",
    "|.|. . . .|. .|\n",
    "+-+-------+---+\n"
  ), 'same arbitrary type');
	is_deeply(SudokuType->new([
    0, 0, 0, 1,
    0, 1, 1, 1,
    2, 3, 3, 3,
    2, 2, 2, 3,
  ]), SudokuType::guess(join '',
    ". ..|.\n",
    "  --  \n",
    ".|.. .\n",
    "------\n",
    ".|.. .\n",
    "  --  \n",
    ". ..|.\n"
  ), 'same arbitrary type');
	is_deeply(SudokuType->new([
    0, 0, 0, 1,
    0, 1, 1, 1,
    2, 3, 3, 3,
    2, 2, 2, 3,
  ]), SudokuType::guess(join '',
    "...|.\n",
    "  /  \n",
    ".|...\n",
    "-----\n",
    ".|...\n",
    " --- \n",
    "...|.\n"
  ), 'same arbitrary type');
	is_deeply(SudokuType->new([
    0, 0, 0, 1,
    0, 1, 1, 1,
    2, 3, 3, 3,
    2, 2, 2, 3,
  ]), SudokuType::guess(join '',
    "...,.",
    ".!!...\n",
    "\n",
    ".@#...",
    "..._."
  ), 'same arbitrary type');
	is_deeply(SudokuType->new([
    0, 0, 0, 1,
    0, 1, 1, 1,
    2, 3, 3, 3,
    2, 2, 2, 3,
  ]), SudokuType::guess(
    "...,..=]...\n\n.:)......_."
  ), 'same arbitrary type');

};

done_testing();
