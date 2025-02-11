package Algorithm::X::ExactCoverProblem;

use strict;
use warnings;

require 5.06.0;

use Carp;

# Constructor with width and secondary_columns
sub new {
  my ($class, $width, $rows_ref, $secondary_columns) = @_;
  $width             = 0 unless defined $width;
  $secondary_columns = 0 unless defined $secondary_columns;

  my $self = bless {
    rows_               => [],
    width_              => $width,
    secondary_columns_  => $secondary_columns,
  }, $class;
  
  if ($secondary_columns > $width) {
    croak("secondary_columns > width");
  }
  
  if (defined $rows_ref) {
    foreach my $row (@$rows_ref) {
      $self->add_row($row);
    }
  }
  
  return $self;
}

# Factory method for a dense ExactCoverProblem (binary matrix)
sub dense {
  my ($class, $bit_rows_ref, $secondary_columns) = @_;
  
  if (!@$bit_rows_ref) {
    return $class->new(0, undef, $secondary_columns);
  }

  my $width = scalar @{$bit_rows_ref->[0]};
  my $problem = $class->new($width, undef, $secondary_columns);

  foreach my $bits (@$bit_rows_ref) {
    if (scalar @$bits != $width) {
      croak("rows have different lengths");
    }
    
    my @row;
    for (my $i = 0; $i < @$bits; ++$i) {
      if ($bits->[$i] != 0 && $bits->[$i] != 1) {
        croak("dense matrix must contain only 0s and 1s");
      }
      push @row, $i if $bits->[$i];
    }
    $problem->add_row(\@row);
  }

  return $problem;
}

# Accessors
sub width {
  my ($self) = @_;
  return $self->{width_};
}

sub rows {
  my ($self) = @_;
  return $self->{rows_};
}

sub secondary_columns {
  my ($self) = @_;
  return $self->{secondary_columns_};
}

sub add_row {
  my ($self, $row_ref) = @_;
  
  my @row = sort { $a <=> $b } @$row_ref;
  foreach my $x (@row) {
    if ($x >= $self->{width_}) {
      croak("column out of range");
    }
  }

  for (my $i = 1; $i < @row; ++$i) {
    if ($row[$i - 1] == $row[$i]) {
      croak("duplicate columns");
    }
  }

  push @{$self->{rows_}}, \@row;
}

# Override stringification
use overload
    '""' => \&stringify;

sub stringify {
  my ($self) = @_;
  my $output = $self->width() . ' ' . $self->secondary_columns() . "\n";
  foreach my $row (@{$self->rows()}) {
    $output .= join(' ', @$row) . "\n";
  }
  return $output;
}

1;

