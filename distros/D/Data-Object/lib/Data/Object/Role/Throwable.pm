package Data::Object::Role::Throwable;

use strict;
use warnings;

use Data::Object::Role;

# BUILD
# METHODS

sub throw {
  my ($self, @args) = @_;

  require Data::Object::Export;

  my $class = Data::Object::Export::load('Data::Object::Exception');

  unshift @args, ref($args[0]) ? 'object' : 'message' if @args == 1;

  @_ = ($class => (object => $self, @args));

  goto $class->can('throw');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Role::Throwable

=cut

=head1 ABSTRACT

Data-Object Throwable Role

=cut

=head1 SYNOPSIS

  use Data::Object::Class;

  with 'Data::Object::Role::Throwable';

=cut

=head1 DESCRIPTION

Data::Object::Role::Throwable provides routines for operating on Perl 5
data objects which meet the criteria for being throwable.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 throw

  throw(Str $arg1) : Object

The throw method throws an exception with the object and message.

=over 4

=item throw example

  $self->throw($message);

=back

=cut
