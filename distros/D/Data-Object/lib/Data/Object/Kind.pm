package Data::Object::Kind;

use strict;
use warnings;

# BUILD
# METHODS

sub class {
  my ($self) = @_;

  my $class = ref $self || $self;

  return $class;
}

sub space {
  my $self = $_[-1];

  my $class = ref $self || $self;

  require Data::Object::Space;

  return Data::Object::Space->new($class);
}

1;

=encoding utf8

=head1 NAME

Data::Object::Kind

=cut

=head1 ABSTRACT

Data-Object Kind Class

=cut

=head1 SYNOPSIS

  use parent 'Data::Object::Kind';

=cut

=head1 DESCRIPTION

Data::Object::Kind is an abstract base class that mostly provides identity and
classification for L<Data::Object> classes, and common routines for operating
on any type of Data-Object object.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 class

  # given $self (Foo::Bar)

  $self->class();

  # Foo::Bar (string)

The class method returns the class name for the given class or object.

=cut

=head2 space

  # given $self (Foo::Bar)

  $self->space();

  # Foo::Bar (space object)

  $self->space('Foo/Baz');

  # Foo::Baz (space object)

The space method returns a L<Data::Object::Space> object for the given class,
object or argument.

=cut
