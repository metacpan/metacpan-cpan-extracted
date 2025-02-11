package NQueens;

use strict;
use warnings;

use Carp;
use Algorithm::X::ExactCoverProblem;
use Algorithm::X::DLX;

sub new { 
  my ($class, $n) = @_;
  croak "Number of queens must be greater than 0" if $n <= 0;

  my $D = $n + $n - 1;
  my @row_data;
  my $problem = Algorithm::X::ExactCoverProblem->new(6 * $n - 2, undef, 4 * $n - 2);

  for my $y (0 .. $n - 1) {
    for my $x (0 .. $n - 1) {
      push @row_data, { x => $x, y => $y };
      my $d1 = $x + $y;
      my $d2 = $x + $n - $y - 1;
      $problem->add_row([$d1, $D + $d2, $D + $D + $x, $D + $D + $n + $y]);
    } 
  }
  return bless { n_ => $n, problem_ => $problem, row_data_ => \@row_data, }, $class;
} 

sub count_solutions {
  my ($self) = @_;
  my $dlx = Algorithm::X::DLX->new($self->{problem_});
  return $dlx->count_solutions();
} 

sub find_solutions { 
  my ($self) = @_;

  my @solutions;
  my $dlx = Algorithm::X::DLX->new($self->{problem_});
  for my $used_rows (@{$dlx->find_solutions()}) {
    my @solution = (0) x $self->{n_};
    for my $i (@$used_rows) {
      my ($x, $y) = @{$self->{row_data_}[$i]}{qw(x y)};
      $solution[$y] = $x;
    } 
    push @solutions, \@solution;
  } 
  return \@solutions;
} 

sub problem {
  my ($self) = @_;
  return $self->{problem_};
}

1; 

