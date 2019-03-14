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

=head2 aliases

  aliases() : ArrayRef

The aliases method returns aliases to register in the type library.

=over 4

=item aliases example

  my $aliases = $self->aliases();

=back

=cut

=head2 name

  name() : StrObject

The name method returns the name of the data type.

=over 4

=item name example

  my $name = $self->name();

=back

=cut

=head2 validation

  validation(Object $arg1) : NumObject

The validation method returns truthy if type check is valid.

=over 4

=item validation example

  my $validation = $self->validation();

=back

=cut
