package SudokuGenerator;

use strict;
use warnings;

use List::Util qw(shuffle);

use SudokuSolver;
use Sudoku;

sub new {
  my $class = shift;
  my $self = {
#    engine => Math::Random::MT::Auto->new(
#      seed => int(time() ^ ($$ + ($$ << 15)))
#    )
  };
  bless $self, $class;
  return $self;
}

sub generate {
  my ($self, $type) = @_;
  my $sudoku = SudokuSolver::random_solution(Sudoku->new($type));

  my @yxs = (0 .. $type->size() - 1);
  while (1) {
    @yxs = shuffle(@yxs);
    my $deletions = 0;

    foreach my $yx (@yxs) {
      my $d = $sudoku->get_value($yx);

      if ($d != 0) {
        $sudoku->set_value($yx, 0);
        my $cnt = $self->count_solutions($sudoku);
        if ($cnt != 1) {
          $sudoku->set_value($yx, $d);

        } else {
          $deletions++;
        }
      }
    }
    return $sudoku if $deletions == 0;
  }
}

sub count_solutions {
  my ($self, $sudoku) = @_;

  eval {
    my $solved = SudokuSolver::solve($sudoku);
  };
  if ($@) {
    if ($@ =~ /No solution/) {
      return 0;
    }
    elsif ($@ =~ /Multiple solutions/) {
      return 2;
    }
    die $@;

  } else {
    return 1;
  }
}

1;


