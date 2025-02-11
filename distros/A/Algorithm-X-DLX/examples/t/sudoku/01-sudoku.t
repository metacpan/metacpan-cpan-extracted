#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

BEGIN {my $p = $0; $p=~ s|/[^/]+$||; unshift @INC, "$p/../../sudoku/" }
use Sudoku;
BEGIN { shift @INC }

subtest 'to string format' => sub {
  plan tests => 1;
  my $type = SudokuType->new(4);
  my $format = SudokuFormat->new($type, join '', 
    "..|..\n",
    "..|..\n",
    "--|--\n",
    "..|..\n",
    "..|..\n",
  );

  my $sudoku = Sudoku->new($type);
  $sudoku->set_value(0, 0);
  $sudoku->set_value(3, 4);
  $sudoku->set_value(4, 2);
  $sudoku->set_value(9, 1);
  $sudoku->set_value(14, 1);
  is(join('',
    "..|.4\n",
    "2.|..\n",
    "--|--\n",
    ".1|..\n",
    "..|1.\n"
  ), $sudoku->to_string_format($format), 'to_string_format');
};
subtest 'from_string' => sub {
  plan tests => 26;
  throws_ok { Sudoku->new("") } qr/Got empty string/i, 'needs char';
  lives_ok { Sudoku->new(".") } 'empty cell suffices';
  lives_ok { Sudoku->new("0") } '1 cell suffices';
  lives_ok { Sudoku->new("1") } '1 cell suffices';
  lives_ok { Sudoku->new("( 1 )") } '1 cell suffices';

  lives_ok { Sudoku->new("2") } '1 cell suffices';
  lives_ok { Sudoku->new("A") } '1 cell suffices';
  lives_ok { Sudoku->new("z") } '1 cell suffices';

  throws_ok { Sudoku->new("ABCD .... .... ...E") } qr/Too many different labels/i, 'labels exceed n';
  lives_ok { Sudoku->new("ABCD .... .... ...A") } 'labels == n';

  my $sudoku = Sudoku->new(join '', 
    "1.|..",
    "..|.2",
    "-----",
    ".1|..",
    "..|3."
  );
  is( 1, $sudoku->get_value(0) );
  is( 0, $sudoku->get_value(1) );
  is( 0, $sudoku->get_value(2) );
  is( 0, $sudoku->get_value(3) );
  is( 0, $sudoku->get_value(4) );
  is( 0, $sudoku->get_value(5) );
  is( 0, $sudoku->get_value(6) );
  is( 2, $sudoku->get_value(7) );
  is( 0, $sudoku->get_value(8) );
  is( 1, $sudoku->get_value(9) );
  is( 0, $sudoku->get_value(10) );
  is( 0, $sudoku->get_value(11) );
  is( 0, $sudoku->get_value(12) );
  is( 0, $sudoku->get_value(13) );
  is( 3, $sudoku->get_value(14) );
  is( 0, $sudoku->get_value(15) );
};

subtest 'is_valid' => sub {
  plan tests => 4;
  ok( ! Sudoku->new(join '',
      "1.|1.",
      "..|..",
      "-----",
      "..|..",
      "..|.."
    )->is_valid(), 'invalid' );
  ok( ! Sudoku->new(join '',
      "1.|..",
      "..|..",
      "-----",
      "1.|..",
      "..|.."
    )->is_valid(), 'invalid' );
  ok( ! Sudoku->new(join '',
      "1.|..",
      ".1|..",
      "-----",
      "..|..",
      "..|.."
    )->is_valid(), 'invalid' );
  ok( Sudoku->new(join '',
      "1.|..",
      "..|1.",
      "-----",
      ".1|..",
      "..|.1",
    )->is_valid(), 'valid' );
};


subtest 'is_solved' => sub {
  plan tests => 4;
  ok( ! Sudoku->new(".")->is_solved(), 'unsolved' );
  ok( Sudoku->new("1")->is_solved(), 'solved' );
  ok( ! Sudoku->new(join '',
    "12|3.",
    "34|12",
    "-----",
    "43|21",
    "21|43"
    )->is_solved(), 'unsolved' );
  ok( Sudoku->new(join '',
    "12|34",
    "34|12",
    "-----",
    "43|21",
    "21|43"
    )->is_solved(), 'solved' );
};

done_testing();
