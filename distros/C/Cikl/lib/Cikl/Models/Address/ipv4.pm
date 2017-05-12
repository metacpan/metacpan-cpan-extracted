package Cikl::Models::Address::ipv4;
use strict;
use warnings;
use Mouse;
use Cikl::Models::AddressRole;
use Cikl::DataTypes::Ipv4;
use namespace::autoclean;
with 'Cikl::Models::AddressRole';

sub type { 'ipv4' }

has '+value' => (
  isa => 'Cikl::DataTypes::Ipv4'
);

sub normalize_value {
  my $class = shift;
  my $value = shift;
  return $value unless ($value && ref($value) eq '');
  $value =~ s/^\s+//;
  $value =~ s/\s+$//;
  return $value;
}

__PACKAGE__->meta->make_immutable;
1;

