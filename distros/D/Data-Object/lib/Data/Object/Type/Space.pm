package Data::Object::Type::Space;

use strict;
use warnings;

use Data::Object::Export;

use parent 'Data::Object::Type';

our $VERSION = '0.97'; # VERSION

# BUILD
# METHODS

sub name {
  return 'DoSpace';
}

sub aliases {
  return ['SpaceObj', 'SpaceObject'];
}

sub coercions {
  return ['Str', sub { do('space', $_[0]) }];
}

sub validation {
  my ($self, $data) = @_;

  return 0 if !$data->isa('Data::Object::Space');

  return 1;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Type::Space

=cut

=head1 ABSTRACT

Data-Object Space Type Constraint

=cut

=head1 SYNOPSIS

  package App::Type::Library;

  use Type::Library -base;

  use Data::Object::Type::Space;

  register Data::Object::Type::Space;

  1;

=cut

=head1 DESCRIPTION

Type constraint for validating L<Data::Object::Space> objects. This type
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

=head2 coercions

  coercions() : ArrayRef

The coercions method returns coercions to configure on the type constraint.

=over 4

=item coercions example

  my $coercions = $self->coercions();

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
