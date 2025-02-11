package Langford;
use strict;
use warnings;

use Algorithm::X::ExactCoverProblem;

sub new {
  my ($class, $n) = @_;
  my $self = {
    n_ => $n,
    row_data_ => [],
    problem_ => Algorithm::X::ExactCoverProblem->new(3 * $n)
  };

  for my $value (1 .. $n) {
    for my $pos (0 .. 2 * $n - $value - 2) {
      next if $value == 1 && $pos + 2 > $n;
      push @{$self->{row_data_}}, { value => $value, left_pos => $pos };
      $self->{problem_}->add_row([$value - 1, $n + $pos, $n + $pos + $value + 1]);
    }
  }
  return bless $self, $class;
}

sub problem {
  my ($self) = @_;
  return $self->{problem_};
}

sub make_solution {
  my ($self, $used_rows) = @_;
  my @solution = (0) x (2 * $self->{n_});
  foreach my $i (@$used_rows) {
    my $pos = $self->{row_data_}[$i]{left_pos};
    my $value = $self->{row_data_}[$i]{value};
    $solution[$pos] = $value;
    $solution[$pos + $value + 1] = $value;
  }
  return \@solution;
} 1;

