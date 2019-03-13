package Data::Object::Type::Yaml;

use strict;
use warnings;

use Data::Object::Export;

use parent 'Data::Object::Type';

# BUILD
# METHODS

sub name {
  return 'DoYaml';
}

sub aliases {
  return ['YamlObj', 'YamlObject'];
}

sub validation {
  my ($self, $data) = @_;

  return 0 if !$data->isa('Data::Object::Yaml');

  return 1;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Type::Yaml

=cut

=head1 ABSTRACT

Data-Object Yaml Type Constraint

=cut

=head1 SYNOPSIS

  package App::Type::Library;

  use Type::Library -base;

  use Data::Object::Type::Yaml;

  register Data::Object::Type::Yaml;

  1;

=cut

=head1 DESCRIPTION

Type constraint for validating L<Data::Object::Yaml> objects. This type
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
