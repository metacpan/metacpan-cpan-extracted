#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 13;
use Test::Exception;

BEGIN {my $p = $0; $p=~ s|/[^/]+$||; unshift @INC, "$p/../../sudoku/" }
use SudokuSolver;
BEGIN { shift @INC }

subtest 'already solved' => sub {
  plan tests => 2;
  my $sudoku = Sudoku->new("846937152319625847752184963285713694463859271971246385127598436638471529594362718");
  ok( $sudoku->is_solved(), 'solved on init' );
  is_deeply( $sudoku, SudokuSolver::solve($sudoku), 'same solution' );
};

subtest 'invalid' => sub {
  plan tests => 4;
  my $sudoku = Sudoku->new('1' x 81);
  ok( ! $sudoku->is_valid(), 'invalid param' );
  dies_ok {SudokuSolver::solve(join '',
    "+--+--+\n",
    "|10|00|\n",
    "|01|00|\n",
    "+--+--+\n",
    "|00|00|\n",
    "|00|00|\n",
    "+--+--+\n"
  )} 'solve fails';
  dies_ok {SudokuSolver::solve(join '',
    "+--+--+\n",
    "|10|01|\n",
    "|00|00|\n",
    "+--+--+\n",
    "|00|00|\n",
    "|00|00|\n",
    "+--+--+\n"
  )} 'solve fails';
  dies_ok {SudokuSolver::solve(join '',
    "+--+--+\n",
    "|10|00|\n",
    "|00|00|\n",
    "+--+--+\n",
    "|00|00|\n",
    "|10|00|\n",
    "+--+--+\n"
  )} 'solve fails';
};

subtest 'almost solved' => sub {
  #plan skip_all => 'cuz I said so';
  diag("Taking some time ...");
  plan tests => 649;
  my $sudoku = Sudoku->new(join '',
    "+---+---+---+\n",
    "|681|739|245|\n",
    "|497|562|813|\n",
    "|523|841|769|\n",
    "+---+---+---+\n",
    "|172|954|386|\n",
    "|865|317|924|\n",
    "|349|628|571|\n",
    "+---+---+---+\n",
    "|916|283|457|\n",
    "|234|175|698|\n",
    "|758|496|132|\n",
    "+---+---+---+\n"
  );
  lives_ok { SudokuSolver::solve($sudoku) } 'valid start';

  # now change any single cell to any other value and expect to die
  my $c = 0;
  for (my $i = 0; $i < $sudoku->size(); ++$i) {
    for (my $digit = 1; $digit <= 9; ++$digit) {
      if ($digit == $sudoku->get_value($i)) {
        next;
      }
      my $old = $sudoku->get_value($i);
      $sudoku->set_value($i, $digit);
      dies_ok { SudokuSolver::solve($sudoku) } "invalid #" . ++$c;
      $sudoku->set_value($i, $old);
    }
  }

};

subtest 'tenpai' => sub {
  # plan skip_all => 'solving 1 field takes waaay too long';
  diag("Taking some time ...");
  plan tests => 81;
  # 2 clones
  my ($solved, $sudoku) = map {Sudoku->new($_)} ((join '',
    "+---+---+---+\n",
    "|681|739|245|\n",
    "|497|562|813|\n",
    "|523|841|769|\n",
    "+---+---+---+\n",
    "|172|954|386|\n",
    "|865|317|924|\n",
    "|349|628|571|\n",
    "+---+---+---+\n",
    "|916|283|457|\n",
    "|234|175|698|\n",
    "|758|496|132|\n",
    "+---+---+---+\n"
  ) x 2);
  
  for (my $i = 0; $i < $sudoku->size(); ++$i) {
    my $digit = $sudoku->get_value($i);
    $sudoku->set_value($i, 0);
    is_deeply( $solved, SudokuSolver::solve($sudoku));
    $sudoku->set_value($i, $digit);
  }
};

subtest 'easy' => sub {
  plan tests => 2;

  my $easy = Sudoku->new(join '',
    "+---+---+---+\n",
    "|14.|8..|97.|\n",
    "|..6|75.|...|\n",
    "|7..|...|..8|\n",
    "+---+---+---+\n",
    "|5..|4.2|.93|\n",
    "|93.|.7.|.82|\n",
    "|62.|9.8|..4|\n",
    "+---+---+---+\n",
    "|4..|...|..9|\n",
    "|...|.15|8..|\n",
    "|.72|..4|.15|\n",
    "+---+---+---+\n"
  );
  my $solved = Sudoku->new(join '',
    "+---+---+---+\n",
    "|145|823|976|\n",
    "|286|759|431|\n",
    "|793|146|528|\n",
    "+---+---+---+\n",
    "|518|462|793|\n",
    "|934|571|682|\n",
    "|627|938|154|\n",
    "+---+---+---+\n",
    "|451|387|269|\n",
    "|369|215|847|\n",
    "|872|694|315|\n",
    "+---+---+---+\n"
  );
  # there is no 'isnt_deeply' in Test::More
  require Data::Dumper; 
  my @cmp = map {Data::Dumper->new([$_])->Sortkeys(1)->Indent(0)->Dump()} ($solved, $easy);
  isnt( $cmp[0], $cmp[1], 'different from start' );
  is_deeply( $solved, SudokuSolver::solve($easy), 'correct solution');
};

subtest 'hard' => sub {
  plan tests => 1;
  my $hard = Sudoku->new(join '',
    "050|002|000",
    "000|100|400",
    "700|000|000",
    "---|---|---",
    "010|700|080",
    "004|030|060",
    "000|500|000",
    "---|---|---",
    "308|060|000",
    "000|000|100",
    "600|000|000"
  );
  my $solved = Sudoku->new(join '',
    "159|482|673",
    "836|175|429",
    "742|693|518",
    "---|---|---",
    "213|746|985",
    "584|239|761",
    "967|518|342",
    "---|---|---",
    "378|961|254",
    "495|827|136",
    "621|354|897"
  );
  is_deeply( $solved, SudokuSolver::solve($hard), 'correct solution');
};

subtest 'region 2x2' => sub {
  plan tests => 1;
  my $puzzle = Sudoku->new(join '',
    "21|..",
    ".3|2.",
    "--+--",
    "..|.4",
    "1.|.."
  );
  my $solved = Sudoku->new(join '',
    "21|43",
    "43|21",
    "--+--",
    "32|14",
    "14|32"
  );
  is_deeply( $solved, SudokuSolver::solve($puzzle), 'correct solution');
};

subtest 'region 3x2' => sub {
  plan tests => 1;
  my $puzzle = Sudoku->new(join '',
    "5.6|...\n",
    "...|.2.\n",
    "---+---\n",
    ".6.|...\n",
    "...|5.1\n",
    "---+---\n",
    "..4|...\n",
    "...|1.3\n"
  );
  my $solved = Sudoku->new(join '',
    "526|314\n",
    "431|625\n",
    "---+---\n",
    "165|432\n",
    "243|561\n",
    "---+---\n",
    "314|256\n",
    "652|143\n"
  );
  is_deeply( $solved, SudokuSolver::solve($puzzle), 'correct solution');
};

subtest 'region 5x2' => sub {
  plan tests => 1;
  my $puzzle = Sudoku->new(join '',
    ".47..|..65.\n",
    "9...5|7...2\n",
    "-----+-----\n",
    "6..41|85..9\n",
    "..92.|.63..\n",
    "-----+-----\n",
    ".92.8|6.47.\n",
    ".A6.4|5.93.\n",
    "-----+-----\n",
    "..36.|.91..\n",
    "8..79|3A..6\n",
    "-----+-----\n",
    "A...6|4...1\n",
    ".14..|..86.\n"
  );
  my $solved = Sudoku->new(join '',
    "147A2|98653\n",
    "96835|74A12\n",
    "-----+-----\n",
    "63A41|85729\n",
    "58927|163A4\n",
    "-----+-----\n",
    "39258|6147A\n",
    "7A614|52938\n",
    "-----+-----\n",
    "4536A|29187\n",
    "82179|3A546\n",
    "-----+-----\n",
    "A7586|43291\n",
    "21493|A7865\n"
  );
  is_deeply( $solved, SudokuSolver::solve($puzzle), 'correct solution');
};

subtest 'custom labels' => sub {
  plan tests => 1;
  my $puzzle = Sudoku->new(join '',
    ".P.|K.R|I.D",
    "D..|B..|..R",
    ".B.|E..|PA.",
    "---+---+---",
    "P..|.KW|A.B",
    "...|...|RK.",
    ".AD|...|...",
    "---+---+---",
    "B..|.E.|..P",
    "A..|...|E..",
    "ER.|P.K|B.."
  );
  my $solved = Sudoku->new(join '',
    "WPE|KAR|IBD",
    "DIA|BWP|KER",
    "RBK|EID|PAW",
    "---+---+---",
    "PER|IKW|ADB",
    "IWB|DPA|RKE",
    "KAD|RBE|WPI",
    "---+---+---",
    "BKW|AEI|DRP",
    "ADP|WRB|EIK",
    "ERI|PDK|BWA"
  );
  is_deeply( $solved, SudokuSolver::solve($puzzle), 'correct solution');
};

subtest 'custom regions' => sub {
  plan tests => 2;
  my $puzzle1 = Sudoku->new(join '',
    "---------------\n",
    "|. .|5 . . 6|4|\n",
    "|   ---     | |\n",
    "|2 . 1|. . .|7|\n",
    "|--   |------ |\n",
    "|.|. .|6 .|. .|\n",
    "| -----   |   |\n",
    "|. .|. . 5|. .|\n",
    "|   |   ----- |\n",
    "|4 3|. .|. .|.|\n",
    "| -------   --|\n",
    "|.|. . 5|4 . .|\n",
    "| |     ---   |\n",
    "|.|4 . 7 .|2 .|\n",
    "---------------\n"
  );
  my $puzzle2 = Sudoku->new(join '',
    "---------------\n",
    "|. 1|3 . . 2|.|\n",
    "|   ---     | |\n",
    "|6 2 .|. . 5|.|\n",
    "|--   |------ |\n",
    "|.|. .|7 .|6 .|\n",
    "| -----   |   |\n",
    "|. .|. 4 .|. .|\n",
    "|   |   ----- |\n",
    "|1 .|. .|. .|.|\n",
    "| -------   --|\n",
    "|.|. . .|. . 6|\n",
    "| |     ---   |\n",
    "|2|. . . 6|. 7|\n",
    "---------------\n"
  );
  my $solved2 = Sudoku->new(join '',
    "---------------\n",
    "|7 1|3 6 4 2|5|\n",
    "|   ---     | |\n",
    "|6 2 4|1 7 5|3|\n",
    "|--   |------ |\n",
    "|4|3 5|7 1|6 2|\n",
    "| -----   |   |\n",
    "|5 6|2 4 3|7 1|\n",
    "|   |   ----- |\n",
    "|1 7|6 5|2 3|4|\n",
    "| -------   --|\n",
    "|3|4 7 2|5 1 6|\n",
    "| |     ---   |\n",
    "|2|5 1 3 6|4 7|\n",
    "---------------\n"
  );
  throws_ok { SudokuSolver::solve($puzzle1) } qr/No solution/i, 'impossible regions';
  is_deeply( $solved2, SudokuSolver::solve($puzzle2), 'correct solution');
};

subtest 'no solution' => sub {
  plan tests => 1;
  throws_ok { SudokuSolver::solve(Sudoku->new(join '',
    "12|3.",
    "..|..",
    "-----",
    "23|1.",
    "..|.."
  )) } qr/No solution/i, 'give up';
};

subtest 'multiple solutions' => sub {
  plan tests => 2;
  lives_ok { SudokuSolver::solve(Sudoku->new(join '',
    "12|34",
    ".3|21",
    "-----",
    "..|12",
    "21|43"
  )) } 'passes';
  throws_ok { SudokuSolver::solve(Sudoku->new(join '',
    "12|34",
    "..|21",
    "-----",
    "..|12",
    "21|43"
  )) } qr/Multiple solutions/i, 'give up';
};

done_testing();

