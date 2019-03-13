package Data::Object::Role::Codifiable;

use strict;
use warnings;

use Data::Object::Role;

# BUILD
# METHODS

sub codify {
  my ($self, @args) = @_;

  require Data::Object::Export;

  return Data::Object::Export::codify(@args);
}

1;

=encoding utf8

=head1 NAME

Data::Object::Role::Codifiable

=cut

=head1 ABSTRACT

Data-Object Codifiable Role

=cut

=head1 SYNOPSIS

  use Data::Object Class;

  with Data::Object::Role::Codifiable;

=cut

=head1 DESCRIPTION

Data::Object::Role::Codifiable is a role which provides functionality for
converting a specially formatted strings into code references.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 codify

  my $codify = $self->codify('($a * $b) + 1_000_000');

Returns a parameterized coderef from a string.

=cut
