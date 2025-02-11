package Polyomino;

use strict;
use warnings;

use Shape;
use Algorithm::X::ExactCoverProblem;

sub new {
  my ($class, $pieces, $area) = @_;
  $pieces //= [Shape::pentominoes()];
  $area //= Polyomino::area(10, 6);
  my $self = {
    area_ => $area,
    index_ => [],
    shapes_ => [],
    size_ => Polyomino::get_size($area),
    row_data_ => [],
    problem_ => Algorithm::X::ExactCoverProblem->new(scalar(@$pieces) + Polyomino::get_size($area))
  };
  bless $self, $class;
  foreach my $piece (@$pieces) {
    push @{$self->{shapes_}}, [$piece->variations()];
  }
  my $height = $self->height();
  my $width = $self->width();
  for (my $y = 0, my $i = 0; $y < $height; ++$y) {
    for (my $x = 0; $x < $width; ++$x) {
      if ($self->{area_}[$y][$x]) {
        $self->{index_}[$y][$x] = $i++;
      }
    }
  }
  for (my $s = 0; $s < @{$self->{shapes_}}; ++$s) {
    for (my $v = 0; $v < @{$self->{shapes_}[$s]}; ++$v) {
      my $shape = $self->{shapes_}[$s][$v];
      for (my $yx = 0; $yx < $self->{size_}; ++$yx) {
        my $y = int($yx / $width);
        my $x = $yx % $width;
        next unless $self->can_put($shape, $x, $y);
        push @{$self->{row_data_}}, { shape => $s, variation => $v, x => $x, y => $y };
        my @row;
        for (my $dyx = 0; $dyx < $shape->size(); ++$dyx) {
          next unless $shape->get_bit($dyx);
          my $dy = int($dyx / $shape->width());
          my $dx = $dyx % $shape->width();
          push @row, $self->{index_}[$y + $dy][$x + $dx];
        }
        push @row, ($self->{size_} + $s);
        $self->{problem_}->add_row(\@row);
      }
    }
  }
  return $self;
}
use Data::Dumper;
sub area {
  my ($width, $height) = @_;
  return [ map { [(1) x $width] } 1..$height ];
}

sub problem {
  my ($self) = @_;
  return $self->{problem_};
}

sub size {
  my ($self) = @_;
  return $self->{size_};
}

sub width {
  my ($self) = @_;
  return scalar(@{$self->{area_}[0]});
}

sub height {
  my ($self) = @_;
  return scalar(@{$self->{area_}});
}

sub make_solution {
  my ($self, $used_rows) = @_;
  my @lines = map { ' ' x $self->width() } 1..$self->height();
  foreach my $i (@$used_rows) {
    my %data = %{$self->{row_data_}[$i]};
    my $shape = $self->{shapes_}[$data{shape}][$data{variation}];
    for (my $y = 0; $y < $shape->height(); ++$y) {
      for (my $x = 0; $x < $shape->width(); ++$x) {
        if ($shape->get_bit($y * $shape->width() + $x)) {
          substr($lines[$data{y} + $y], ($data{x} + $x), 1, $shape->name());
        }
      }
    }
  }
  return \@lines;
}

sub get_size {
  my ($area_ref) = @_;
  my $result = 0;
  foreach my $row (@$area_ref) {
    foreach my $value (@$row) {
      ++$result if ($value);
    }
  }
  return $result;
}

sub can_put {
  my ($self, $shape, $x, $y) = @_;
  for (my $dy = 0; $dy < $shape->height(); ++$dy) {
    for (my $dx = 0; $dx < $shape->width(); ++$dx) {
      if (!$shape->get_bit($dy * $shape->width() + $dx)) {
        next;
      }
      if ($x + $dx >= $self->width() || $y + $dy >= $self->height() || !$self->{area_}[$y + $dy][$x + $dx]) {
        return 0;
      }
    }
  }
  return 1;
}

1;

