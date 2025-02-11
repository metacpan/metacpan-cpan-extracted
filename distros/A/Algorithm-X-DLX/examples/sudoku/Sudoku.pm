package Sudoku;

use strict;
use warnings;

use Carp;
use List::Util qw(min);
use SudokuType;
use SudokuFormat;

sub new {
  my $class = shift;
  (@_ > 0 && @_ < 4) or die "Unknown number of arguments given to constructor of Sudoku.\n";

  my $self = {};
  my $string = '';
  
  foreach my $arg (@_) {
    if (ref($arg) eq 'SudokuType') {
      $self->{type_} = $arg;
    } elsif (ref($arg) eq 'ARRAY') {
      $self->{values_} = [@$arg];
    } elsif (defined $arg && !ref($arg)) {
      croak "Got empty string" unless length $arg;
      $string = $arg;
    } else {
      die "Unknown blessed parameter.\n";
    }
  }

  if (! $self->{type_} && $string ) {
   $self->{type_} = SudokuType::guess($string);
  }

  if (! $self->{values_} && $string ) {
   $self->{values_} = SudokuFormat::get_values($string);
  }
  
  $self->{type_}   ||= SudokuType->new();
  $self->{values_} ||= [(0) x $self->{type_}->size()];

  return bless $self, $class;
}

sub type {
  my ($self) = @_;
  return $self->{type_};
}

sub size {
  my ($self) = @_;
  return $self->{type_}->size();
}

sub is_empty {
  my ($self) = @_;
  for my $v (@{$self->{values_}}) {
    return 0 if $v > 0;
  }
  return 1;
}

sub is_valid {
  my ($self) = @_;
  my $n = $self->{type_}->n();
  
  for (my $i = 0; $i < $self->{type_}->size(); ++$i) {
    for(my $j = $i + 1; $j < $self->{type_}->size(); ++$j) {
      my $a = $self->{values_}[$i];
      my $b = $self->{values_}[$j];
      next if $a == 0 || $a != $b;
      # 2 cells have same value, check for same column, row or region
      return 0 if ($i % $n == $j % $n);
      return 0 if (int($i / $n) == int($j / $n));
      return 0 if ($self->{type_}->region($i) == $self->{type_}->region($j));
    }
  }
  return 1;
}

sub is_solved {
  my ($self) = @_;
  return $self->is_valid() && (min(@{$self->{values_}}) > 0);
}

sub get_value {
  my ($self, $pos) = @_;
  return $self->{values_}[$pos];
}

sub set_value {
  my ($self, $pos, $value) = @_;
  $self->{values_}[$pos] = $value;
}

sub equals {
  my ($self, $other) = @_;
  return ($self->{type_} == $other->{type_}) && (array_equals($self->{values_}, $other->{values_}));
}

sub array_equals {
  my ($a1, $a2) = @_;
  # a replacement for the smartmatch operator '~~', giving warnings (experimental) since 5.18
  # optional modules: List::Compare, Array::Compare, Data::Compare
  my $match = @$a1 == @$a2 && !grep { !$_ } map { $a1->[$_] eq $a2->[$_] } 0 .. $#$a1;
  return $match
}

sub not_equals {
  my ($self, $other) = @_;
  return !($self->equals($other));
}

sub to_string {
  my ($self) = @_;
  return $self->to_string_format(SudokuFormat->new($self->{type_}));
}

sub to_string_format {
  my ($self, $format) = @_;
  die "Invalid format" if $format->type() != $self->{type_};
  return $format->to_string(@{$self->{values_}});
}

1;

