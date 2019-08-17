package Data::Object::Base;

use strict;
use warnings;

our $VERSION = '0.98'; # VERSION

# BUILD
# METHODS

sub class {
  my ($self) = @_;

  my $class = ref $self || $self;

  return $class;
}

sub space {
  my ($self) = (pop);

  my $class = ref $self || $self;

  require Data::Object::Space;

  return Data::Object::Space->new($class);
}

sub type {
  my ($self) = @_;

  require Data::Object::Export;

  return Data::Object::Export::deduce_type($self);
}

1;

=encoding utf8

=head1 NAME

Data::Object::Base

=cut

=head1 ABSTRACT

Data-Object Base Class

=cut

=head1 SYNOPSIS

  use parent 'Data::Object::Base';

=cut

=head1 DESCRIPTION

Data::Object::Base is an abstract base class that mostly provides identity and
classification for L<Data::Object> classes, and common routines for operating
on any type of Data-Object object.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 class

  class() : Str

The class method returns the class name for the given class or object.

=over 4

=item class example

  # given $self (Foo::Bar)

  $self->class();

  # Foo::Bar (string)

=back

=cut

=head2 space

  space(Str $arg1) : Object

The space method returns a L<Data::Object::Space> object for the given class,
object or argument.

=over 4

=item space example

  # given $self (Foo::Bar)

  $self->space();

  # Foo::Bar (space object)

  $self->space('Foo/Baz');

  # Foo::Baz (space object)

=back

=cut

=head2 type

  type() : Str

The type method returns object type string.

=over 4

=item type example

  my $type = $self->type();

=back

=cut
