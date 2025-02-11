package Algorithm::X::LinkedMatrix;

use strict;
use warnings;

require 5.06.0;

use Carp;
use Algorithm::X::ExactCoverProblem;

sub new {
  my ($class, $problem) = @_;

  my $self = {
    col_ids => [],
    sizes   => [(0) x $problem->width()],
    nodes   => [],
  };
  bless $self, $class;

  my $root = $self->create_node(~0, ~0);
  croak "Root ID mismatch" unless $root == $self->root_id();

  for my $x (0 .. $problem->width() - 1) {
    my $id = $self->create_node($x, ~0);
    $self->{col_ids}[$x] = $id;
    if ($x >= $problem->secondary_columns()) {
      $self->{nodes}[$id]{r} = $root;
      $self->{nodes}[$id]{l} = $self->L($root);
      $self->{nodes}[$self->L($root)]->{r} = $id;
      $self->{nodes}[$root]->{l} = $id;
    }
  }

  for my $y (0 .. $#{$problem->rows()}) {
    $self->add_row($y, $problem->rows()->[$y]);
  }

  return $self;
}

sub add_row {
  my ($self, $y, $xs) = @_;

  my $first_id = 0;

  for my $x (@$xs) {
    my $id = $self->create_node($x, $y);
    $self->{nodes}[$id]{d} = $self->C($id);
    $self->{nodes}[$id]{u} = $self->U($self->C($id));
    $self->{nodes}[$self->U($self->C($id))]->{d} = $id;
    $self->{nodes}[$self->C($id)]->{u} = $id;
    $self->{sizes}[$x]++;

    if ($first_id == 0) {
      $first_id = $id;

    } else {
      $self->{nodes}[$id]{r} = $first_id;
      $self->{nodes}[$id]{l} = $self->L($first_id);
      $self->{nodes}[$self->L($first_id)]->{r} = $id;
      $self->{nodes}[$first_id]->{l} = $id;
    }
  }
}

sub cover_column {
  my ($self, $c) = @_;
  $c = $self->C($c);

  $self->{nodes}[$self->L($c)]->{r} = $self->R($c);
  $self->{nodes}[$self->R($c)]->{l} = $self->L($c);
  
  for (my $i = $self->D($c); $i != $c; $i = $self->D($i)) {
    for (my $j = $self->R($i); $j != $i; $j = $self->R($j)) {
      $self->{nodes}[$self->U($j)]->{d} = $self->D($j);
      $self->{nodes}[$self->D($j)]->{u} = $self->U($j);
      $self->{sizes}[$self->X($j)]--;
    }
  }
}

sub uncover_column {
  my ($self, $c) = @_;
  $c = $self->C($c);
  
  for (my $i = $self->U($c); $i != $c; $i = $self->U($i)) {
    for (my $j = $self->L($i); $j != $i; $j = $self->L($j)) {
      $self->{nodes}[$self->U($j)]->{d} = $j;
      $self->{nodes}[$self->D($j)]->{u} = $j;
      $self->{sizes}[$self->X($j)]++;
    }
  }
  $self->{nodes}[$self->L($c)]->{r} = $c;
  $self->{nodes}[$self->R($c)]->{l} = $c;
}

sub create_node {
  my ($self, $x, $y) = @_;

  croak "Invalid node creation" unless $x <= $self->width() || $x == ~0;
  my $id = scalar @{$self->{nodes}};
  push @{$self->{nodes}}, { id => $id, x => $x, y => $y, l => $id, r => $id, u => $id, d => $id };
  return $id;
}

sub width { my ($self) = @_; return scalar @{$self->{col_ids}} }
sub root_id { return 0 }
sub X { my ($self, $id) = @_;  return $self->{nodes}[$id]{x}; } # column id
sub Y { my ($self, $id) = @_;  return $self->{nodes}[$id]{y}; } # row id
sub S { my ($self, $id) = @_;  return $self->{sizes}[$self->X($id)]; } # node count in same column
sub C { my ($self, $id) = @_;  return $self->{col_ids}[$self->X($id)]; } # last node in same column
sub L { my ($self, $id) = @_;  return $self->{nodes}[$id]{l}; } # left node
sub R { my ($self, $id) = @_;  return $self->{nodes}[$id]{r}; } # right node
sub U { my ($self, $id) = @_;  return $self->{nodes}[$id]{u}; } # upward node
sub D { my ($self, $id) = @_;  return $self->{nodes}[$id]{d}; } # downward node

1;

