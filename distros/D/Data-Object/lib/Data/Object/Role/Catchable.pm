package Data::Object::Role::Catchable;

use strict;
use warnings;

use Data::Object::Role;

our $VERSION = '0.96'; # VERSION

# BUILD
# METHODS

sub catch {
  my ($self, $error, $kind) = @_;

  $kind = ref($self) if !$kind;

  return UNIVERSAL::isa($error->object, $kind) ? 1 : 0;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Role::Catchable

=cut

=head1 ABSTRACT

Data-Object Catchable Role

=cut

=head1 SYNOPSIS

  use Data::Object 'Class';

  with Data::Object::Role::Catchable;

=cut

=head1 DESCRIPTION

Data::Object::Role::Catchable is a role which provides functionality for
catching thrown exceptions.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 catch

  catch(Object $arg1, ClassName $arg2) : Int

Returns truthy if the objects passed are of the same kind.

=over 4

=item catch example

  my $catch = $self->catch($object, 'App::Exception');

=back

=cut
