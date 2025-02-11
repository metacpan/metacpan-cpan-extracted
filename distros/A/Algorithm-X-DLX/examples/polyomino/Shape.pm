package Shape;
use strict;
use warnings;

use List::Util qw(reduce);
use Carp;

sub new {
  my ($class, $name, $bits) = @_;
  # Handle different constructor calls 
  if (!defined $name) {
    #return bless { name => '#', bits => [], width => 0, height => 0 }, $class;
    $name = '#';
    $bits = [];
  } elsif (ref($name) eq 'ARRAY') {
    #return bless { name => '#', bits => $name, width => @{$name ? $name->[0] : []}, height => scalar @$name }, $class;
    $bits = $name;
    $name = '#';
  }
  my $self = {
    name => $name,
    bits => $bits,
    width => (@$bits ? scalar @{$bits->[0]} : 0),
    height => scalar @$bits,
  };
  # Assert that all rows have the same width
  $self->{content} = '';
  for my $row (@$bits) {
    croak "Row width mismatch" unless @$row == $self->{width};
    $self->{content} .= join('', @$row) . ',';
  }
  return bless $self, $class;
}

sub pentominoes {
  return (
    Shape->new('I', [[1, 1, 1, 1, 1]]),
    Shape->new('N', [[1, 1, 1, 0], [0, 0, 1, 1]]),
    Shape->new('L', [[1, 1, 1, 1], [1, 0, 0, 0]]),
    Shape->new('Y', [[1, 1, 1, 1], [0, 1, 0, 0]]),
    Shape->new('P', [[1, 1, 1], [1, 1, 0]]),
    Shape->new('C', [[1, 1, 1], [1, 0, 1]]),
    Shape->new('V', [[1, 1, 1], [1, 0, 0], [1, 0, 0]]),
    Shape->new('T', [[1, 1, 1], [0, 1, 0], [0, 1, 0]]),
    Shape->new('F', [[1, 1, 0], [0, 1, 1], [0, 1, 0]]),
    Shape->new('Z', [[1, 1, 0], [0, 1, 0], [0, 1, 1]]),
    Shape->new('W', [[1, 1, 0], [0, 1, 1], [0, 0, 1]]),
    Shape->new('X', [[0, 1, 0], [1, 1, 1], [0, 1, 0]]),
  );
}

sub rotate {
  my ($self) = @_;
  my @rows = map { [(undef) x $self->{height}] } (1 .. $self->{width});
  for my $y (0 .. $self->{height} - 1) {
    for my $x (0 .. $self->{width} - 1) {
      $rows[$x][$self->{height} - $y - 1] = $self->{bits}[$y][$x];
    }
  }
  return Shape->new($self->{name}, \@rows);
}

sub reflect {
  my ($self) = @_;
  my @rows = map { [reverse @$_] } @{$self->{bits}};
  return Shape->new($self->{name}, \@rows);
}

sub rotations {
  my ($self) = @_;
  my @result = ($self);
  my $shape = $self->rotate();
#TODO: compare shapes
  while ($shape->not_equals($result[0])) {
    push @result, $shape;
    $shape = $shape->rotate();
  }
  return @result;
}

sub reflections {
  my ($self) = @_;
  my @refl = ($self->reflect());
  for my $rot ($self->rotations()) {
#TODO: compare shapes
    return ($self) if $rot->equals($refl[0]);
  }
  return ($self, @refl);
}

sub variations {
  my ($self) = @_;
  my @vars;
  for my $refl ($self->reflections()) {
    push @vars, $refl->rotations();
  }
  return @vars;
}

sub name {
  return shift->{name};
}

sub width {
  return shift->{width};
}

sub height {
  return shift->{height};
}

sub size {
  my ($self) = @_;
  return $self->{width} * $self->{height};
}

sub get_bit {
  my ($self, $yx) = @_;
  return $self->{bits}[$yx / $self->{width}][$yx % $self->{width}];
}

use Data::Dumper;
sub equals {
  my ($self, $rhs) = @_;

#print Dumper($self->{content}), "\n  == ? \n" , Dumper($rhs->{content});
#exit 0;
  return $self->{content} eq $rhs->{content};
#  return reduce { $a &&= $_ eq $_[2] } (map { $_ eq $_[2] } @{$rhs->{bits}}) == scalar(@{$rhs->{bits}});
}

sub not_equals {
  my ($self, $rhs) = @_;
  return !($self->equals($rhs));
}

sub less_than {
  my ($self, $rhs) = @_;
  return join(',', map { join(',', @$_) } @{$self->{bits}}) lt join(',', map { join(',', @$_) } @{$rhs->{bits}});
}

1; # End of package return true;
