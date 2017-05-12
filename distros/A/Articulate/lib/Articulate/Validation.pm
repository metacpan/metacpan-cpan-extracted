package Articulate::Validation;
use strict;
use warnings;

use Moo;

with 'Articulate::Role::Component';
use Articulate::Syntax qw(instantiate_array);

=head1 NAME

Articulate::Validation - ensure content is valid before accepting it.

=head1 DESCRIPTION

  use Articulate::Validation;
  $validation->validate($item) or throw_error;

Validators should return a true argument if either a) The item is valid, or b) The validator has no opinion on the item.

=head1 METHODS

=head3 validate

Iterates through the validators. Returns false if any has a false result. Returns true otherwise.

=cut

=head1 ATTTRIBUTES

=head3 validators

An arrayref of the classes which provide a validate function, in the order in which they will be asked to validate items.

=cut

has validators => (
  is      => 'rw',
  default => sub { [] },
  coerce  => sub { instantiate_array @_ }
);

sub validate {
  my $self = shift;
  my $item = shift;
  foreach my $validator ( @{ $self->validators } ) {
    my $result = $validator->validate($item);
    return $result unless $result;
  }
  return 1;
}

1;
