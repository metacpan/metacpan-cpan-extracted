#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

BEGIN {my $p = $0; $p=~ s|/[^/]+$||; unshift @INC, "$p/../../sudoku/" }
use SudokuGenerator;
BEGIN { shift @INC }

subtest 'small sudoku' => sub {
  plan tests => 3;
  my $generator = SudokuGenerator->new();
  my $sudoku = $generator->generate(SudokuType->new(4));
  is( 4, $sudoku->type()->n(), 'generated puzzle size' );
  ok( $sudoku->is_valid(), 'valid puzzle' );
  ok( ! $sudoku->is_solved(), 'unsolved puzzle' );
};

subtest 'standard sudoku' => sub {
  plan tests => 3;
  my $generator = SudokuGenerator->new();
  my $sudoku = $generator->generate(SudokuType->new());
  is( 9, $sudoku->type()->n(), 'generated standard size' );
  ok( $sudoku->is_valid(), 'valid puzzle' );
  ok( ! $sudoku->is_solved(), 'unsolved puzzle' );
};

done_testing();

