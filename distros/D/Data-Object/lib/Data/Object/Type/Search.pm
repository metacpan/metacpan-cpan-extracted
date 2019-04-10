package Data::Object::Type::Search;

use strict;
use warnings;

use parent 'Data::Object::Type';

our $VERSION = '0.96'; # VERSION

# BUILD
# METHODS

sub name {
  return 'DoSearch';
}

sub aliases {
  return ['SearchObj', 'SearchObject'];
}

sub validation {
  my ($self, $data) = @_;

  return 0 if !$data->isa('Data::Object::Search');

  return 1;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Type::Search

=cut

=head1 ABSTRACT

Data-Object Search Type Constraint

=cut

=head1 SYNOPSIS

  package App::Type::Library;

  use Type::Library -base;

  use Data::Object::Type::Search;

  register Data::Object::Type::Search;

  1;

=cut

=head1 DESCRIPTION

Type constraint for validating L<Data::Object::Search> objects. This type
constraint is registered in the L<Data::Object::Library> type library.

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
