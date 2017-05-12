package Cikl::Models::Address::fqdn;
use strict;
use warnings;
use Mouse;
use Cikl::Models::AddressRole;
use Cikl::DataTypes::Fqdn;
use namespace::autoclean;
with 'Cikl::Models::AddressRole';

sub type { 'fqdn' }

has '+value' => (
  isa => 'Cikl::DataTypes::Fqdn'
);

sub normalize_value {
  my $class = shift;
  my $value = shift;
  return $value unless ($value && ref($value) eq '');
  $value =~ s/^\s+//;
  $value =~ s/\s+$//;
  return lc($value);
}

__PACKAGE__->meta->make_immutable;
1;
