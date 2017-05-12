package Cikl::Models::Address::email;
use strict;
use warnings;
use Mouse;
use Cikl::Models::AddressRole;
use namespace::autoclean;
use Cikl::DataTypes::Email;
with 'Cikl::Models::AddressRole';

sub type { 'email' }

has '+value' => (
  isa => 'Cikl::DataTypes::Email',
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
