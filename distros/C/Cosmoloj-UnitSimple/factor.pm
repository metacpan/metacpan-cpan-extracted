package Factor;

use strict;
use warnings;

sub new {
  my ( $class, $unit, $numerator, $denominator ) = @_;
  $class = ref($class) || $class;
  my $this = {};
  bless($this, $class);
  $this->{DIM} = $unit ||= $this;
  $this->{NUMERATOR} = $numerator ||= 1.;
  $this->{DENOMINATOR} = $denominator ||= 1;
  return $this;
}

sub dim {
  my $this = shift;
  return $this->{DIM};
}

sub numerator {
  my $this = shift;
  return $this->{NUMERATOR};
}

sub denominator {
  my $this = shift;
  return $this->{DENOMINATOR};
}

sub power {
  my $this = shift;
  return $this->{NUMERATOR} / $this->{DENOMINATOR};
}

=head1 NAME

Factor - representation of a power of units

=head1 DESCRIPTION

This module maps a conceptual class that represents a power of unit of measurement.

=head1 AUTHOR

Samuel Andres

=head1 LICENSE

UnLicense

=cut

1;
