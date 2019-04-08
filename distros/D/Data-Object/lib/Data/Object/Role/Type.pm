package Data::Object::Role::Type;

use strict;
use warnings;

use feature 'state';

use Data::Object::Role;

our $VERSION = '0.95'; # VERSION

# BUILD
# METHODS

sub methods {
  my ($self) = @_;

  state %methods;

  my $class = ref($self) || $self;

  no strict 'refs';

  if (defined $methods{$class}) {
    return [sort @{$methods{$class}}];
  }
  return [
    sort grep *{"${class}::$_"}{CODE},
    grep /^[_a-zA-Z]/, keys %{"${class}::"}
  ];
}

sub type {
  my ($self) = @_;

  require Data::Object;

  return Data::Object::Export::deduce_type($self);
}

1;

=encoding utf8

=head1 NAME

Data::Object::Role::Type

=cut

=head1 ABSTRACT

Data-Object Type Role

=cut

=head1 SYNOPSIS

  use Data::Object::Class;

  with 'Data::Object::Role::Type';

=cut

=head1 DESCRIPTION

Data::Object::Role::Type provides routines for operating on Perl 5 data
objects which meet the criteria for being considered type objects.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 methods

  methods() : ArrayRef

The methods method returns all object functions and methods.

=over 4

=item methods example

  my $methods = $self->methods();

=back

=cut

=head2 type

  type() : StrObject

The type method returns object type string.

=over 4

=item type example

  my $type = $self->type();

=back

=cut
