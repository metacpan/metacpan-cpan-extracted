package Data::Object::Type::Json;

use strict;
use warnings;

use Data::Object::Export;

use parent 'Data::Object::Type';

# BUILD
# METHODS

sub name {
  return 'DoJson';
}

sub aliases {
  return ['JsonObj', 'JsonObject'];
}

sub validation {
  my ($self, $data) = @_;

  return 0 if !$data->isa('Data::Object::Json');

  return 1;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Type::Json

=cut

=head1 ABSTRACT

Data-Object Json Type Constraint

=cut

=head1 SYNOPSIS

  package App::Type::Library;

  use Type::Library -base;

  use Data::Object::Type::Json;

  register Data::Object::Type::Json;

  1;

=cut

=head1 DESCRIPTION

Type constraint for validating L<Data::Object::Json> objects. This type
constraint is registered in the L<Data::Object::Config::Library> type library.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 name

  my $name = $self->name();

The name method returns the name of the data type.

=cut

=head2 aliases

  my $aliases = $self->aliases();

The aliases method returns aliases to register in the type library.

=cut

=head2 validation

  my $validation = $self->validation();

The validation method returns truthy if type check is valid.

=cut
