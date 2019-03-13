package Data::Object::Type::Exception;

use strict;
use warnings;

use parent 'Data::Object::Type';

# BUILD
# METHODS

sub name {
  return 'DoException';
}

sub aliases {
  return ['ExceptionObj', 'ExceptionObject'];
}

sub validation {
  my ($self, $data) = @_;

  return 0 if !$data->isa('Data::Object::Exception');

  return 1;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Type::Exception

=cut

=head1 ABSTRACT

Data-Object Exception Type Constraint

=cut

=head1 SYNOPSIS

  package App::Type::Library;

  use Type::Library -base;

  use Data::Object::Type::Exception;

  register Data::Object::Type::Exception;

  1;

=cut

=head1 DESCRIPTION

Type constraint for validating L<Data::Object::Exception> objects. This type
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
