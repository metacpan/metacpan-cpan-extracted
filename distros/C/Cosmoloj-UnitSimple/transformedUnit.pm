package TransformedUnit;

use strict;
use warnings;

use unitConverter;
use unit;

# heritage
use base qw( Unit );

sub new {
  my ( $class, $toReference, $reference ) = @_;
  $class = ref($class) || $class;
  my $this = $class->SUPER::new();
  bless($this, $class);
  $this->{TO_REFERENCE} = $toReference;
  $this->{REFERENCE} = $reference;
  return $this;
}

sub toReference {
  my $this = shift;
  return $this->{TO_REFERENCE};
}

sub reference {
  my $this = shift;
  return $this->{REFERENCE};
}

sub toBase {
  my $this = shift;
  return $this->reference->toBase->concatenate($this->toReference);
}

=head1 NAME

TransformedUnit - representation of an unit based on a referenced unit and an unit conversion

=head1 DESCRIPTION

This module maps a conceptual class that represents an unit based on a referenced unit and an unit conversion.

=head1 AUTHOR

Samuel Andres

=head1 LICENSE

UnLicense

=cut

1;
