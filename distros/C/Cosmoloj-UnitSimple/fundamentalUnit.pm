package FundamentalUnit;

use strict;
use warnings;

use unitConverter;
use unit;

# heritage
use base qw( Unit );

sub new {
  my ( $class ) = @_;
  $class = ref($class) || $class;
  my $this = $class->SUPER::new();
  bless($this, $class);
  return $this;
}

sub toBase {
  return UnitConverter->identity;
}

=head1 NAME

FundamentalUnit - representation of an unit defined by itself

=head1 DESCRIPTION

This module maps a conceptual class that represents an unit defined by itself.

=head1 AUTHOR

Samuel Andres

=head1 LICENSE

UnLicense

=cut

1;
