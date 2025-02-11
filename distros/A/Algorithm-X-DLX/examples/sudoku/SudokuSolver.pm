package SudokuSolver;

use strict;
use warnings;

use List::Util qw(shuffle);
use Algorithm::X::DLX;
use Algorithm::X::ExactCoverProblem;
use Sudoku;
use Carp;

sub solve {
  my ($sudoku) = @_;
  return solve_impl($sudoku, 0);
}

sub random_solution {
  my ($sudoku) = @_;
  return solve_impl($sudoku, 1);
}

sub solve_impl {
  my ($sudoku, $randomized) = @_;

  unless ($sudoku->is_valid()) {
    croak "solve(): Invalid sudoku";
  }

  my $type = $sudoku->type();
  my $n = $type->n();
  
  my $pack      = sub { $_[0] * $n + $_[1] };
  my $id_cell   = sub { &$pack($_[0], $_[1]) };
  my $id_col    = sub { $type->size() + &$pack($_[0], $_[1]) };
  my $id_row    = sub { 2 * $type->size() + &$pack($_[0], $_[1]) };
  my $id_region = sub { 3 * $type->size() + &$pack($_[0], $_[1]) };

  my @cell_taken = (0) x $type->size();
  my @col_taken = (0) x $type->size();
  my @row_taken = (0) x $type->size();
  my @region_taken = (0) x $type->size();

  for my $i (0 .. $type->size() - 1) {
    if ($sudoku->get_value($i) != 0) {
      my $x = $i % $n;
      my $y = int($i / $n);
      my $d = $sudoku->get_value($i) - 1;
      ++$cell_taken[&$pack($x, $y)];
      ++$col_taken[&$pack($x, $d)];
      ++$row_taken[&$pack($y, $d)];
      ++$region_taken[&$pack($type->region_xy($x, $y), $d)];
    }
  }

  my @matrix;
  
  for my $i (0 .. $n - 1) {
    for my $j (0 .. $n - 1) {
      push @matrix, [&$id_cell($i, $j)]   if ($cell_taken[&$pack($i, $j)]);
      push @matrix, [&$id_col($i, $j)]    if ($col_taken[&$pack($i, $j)]);
      push @matrix, [&$id_row($i, $j)]    if ($row_taken[&$pack($i, $j)]);
      push @matrix, [&$id_region($i, $j)] if ($region_taken[&$pack($i, $j)]);
    }
  }

  my %row_position;
  my %row_digit;

  for my $y (0 .. $n - 1) {
    for my $x (0 .. $n - 1) {
      for my $d (0 .. $n - 1) {
        if ($cell_taken[&$pack($x, $y)]
          || $col_taken[&$pack($x, $d)]
          || $row_taken[&$pack($y, $d)]
          || $region_taken[&$pack($type->region_xy($x, $y), $d)]) {
          next;
        }
        my $row_index = scalar(@matrix);
        # Store the position and digit for later use
        $row_position{$row_index} = ($y * $n + $x);
        $row_digit{$row_index} = $d;
        push @matrix, [
          &$id_cell($x, $y),
          &$id_col($x, $d),
          &$id_row($y, $d),
          &$id_region($type->region_xy($x, $y), $d)
        ];
      }
    }
  }

  my $dlx_options = Algorithm::X::DLX::Options();
  if ($randomized) {
    #static std::random_device rd;
    #static auto engine = std::mt19937(rd());
    #options.choose_random_column = randomized;
    #options.random_engine = &engine;
    $dlx_options->{choose_random_column} = 1;
  }
  $dlx_options->{max_solutions} = $dlx_options->{choose_random_column} ? 1 : 2;

  my $problem = Algorithm::X::ExactCoverProblem->new(4 * $type->size(), \@matrix);
  my $dlx = Algorithm::X::DLX->new($problem);
  my ($dlx_result) = $dlx->search($dlx_options)->{solutions};

  # Collect solutions
  my @solutions;
  
  foreach my $rows (@$dlx_result) {
    my @solved = @{$sudoku->{values_}}; # Copy original sudoku
    foreach my $i (@$rows) {
      if (exists($row_position{$i})) {
        $solved[$row_position{$i}] = $row_digit{$i} + 1;
      }
    }
    push @solutions, Sudoku->new($sudoku->type, \@solved); # Store solved sudoku
  }

  if (!@solutions) {
    croak "No solution";
  }
  
  if (@solutions > 1) {
    croak "Multiple solutions";
  }

  return shift @solutions; # Return the first solution
}

1;

