package UnitConverter;

use strict;
use warnings;

use unit;

sub new {
  my ( $class, $scale, $offset, $inverse ) = @_;
  $class = ref($class) || $class;
  my $this = {};
  bless($this, $class);
  $this->{SCALE} = $scale;
  $this->{OFFSET} = $offset ||= 0.;
  $this->{INVERSE} = $inverse
    ? $inverse
    : ($scale == 1.000000000000000000 && $offset == 0.000000000000000000)
      ? $this # si on détecte l'identité, elle est son propre inverse
      : UnitConverter->new(1. / $scale, -$offset / $scale, $this);
  return $this;
}

sub scale {
  my $this = shift;
  return $this->{SCALE};
}

sub offset {
  my $this = shift;
  return $this->{OFFSET};
}

sub inverse {
  my $this = shift;
  return $this->{INVERSE};
}

sub linear {
  my $this = shift;
  # comparaison volontaire avec un double
  if ($this->offset == 0.000000000000000000) {
    return $this;
  } else {
    return UnitConverter->new($this->scale);
  }
}

sub linearPow {
  my ( $this, $pow ) = @_;
  # comparaison volontaire avec des doubles
  if ($this->offset == 0.00000000000000000 and $pow == 1.00000000000000000) {
    return $this;
  } else {
    return UnitConverter->new($this->scale ** $pow);
  }
}

sub convert {
  my ( $this, $value ) = @_;
  return $value * $this->scale + $this->offset;
}

sub concatenate {
  my ( $this, $converter ) = @_;
  return UnitConverter->new($converter->scale * $this->scale, $this->convert($converter->offset));
}

# static
sub newLinear {
  my ( $class, $scale ) = @_;
  return UnitConverter->new($scale, 0.);
}

# static
sub newTranslation {
  my ( $class, $offset ) = @_;
  return UnitConverter->new(1., $offset);
}

# static
my $identity = UnitConverter->newLinear(1.0);

# static
sub identity {
  return $identity;
}

=head1 NAME

UnitConverter - representation of an unit converter

=head1 DESCRIPTION

This module maps a conceptual class that represents an unit converter.

=head1 AUTHOR

Samuel Andres

=head1 LICENSE

UnLicense

=cut

1;
