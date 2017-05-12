package Cikl::Models::AddressRole;
use strict;
use warnings;
use Mouse::Role;
use namespace::autoclean;

requires 'type';

has 'value' => (
  is => 'rw',
  isa => 'Str',
  required => 1
);

sub as_string {
  my $self = shift;
  return $self->value;
}

sub to_hash {
  return { $_[0]->type => $_[0]->value };
}

sub normalize_value {
  my $class = shift;
  return shift;
}

sub new_normalized {
  my $class = shift;
  my %args = @_;
  $args{value} = $class->normalize_value($args{value});
  $class->new(%args);
}


1;
