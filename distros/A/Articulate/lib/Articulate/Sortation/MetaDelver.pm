package Articulate::Sortation::MetaDelver;
use strict;
use warnings;

use Moo;
with 'Articulate::Role::Sortation::AllYouNeedIsCmp';

use Articulate::Syntax qw(instantiate dpath_get);

=head1 NAME

Articulate::Sortation::MetaDelver - delve into the metadata and sort it

=head1 ATTRIBUTES

=head3 options

A hashref defining what information to get and how to sort it.

=over

=item * C<field>: . This field is mandatory. A C<Data::DPath> expression used to find the right field from the meta, e.g. 'schema/core/dateUpdated' Not that a '/' will be prepended if it does not already exist..

=item * C<cmp> - The type of comparison to apply - any class which provides a C<cmp> method can be entered here. Defaults to C<Articulate::Sortation::String>.

=item * C<order> - The direction in which to sort: C<asc> or C<desc>, defaults to C<asc>.

=back

=head1 METHODS

=head3 sort

Provided by L<Articulate::Role::Sortation::AllYouNeedIsCmp>.

=head3 schwartz

Provided by L<Articulate::Role::Sortation::AllYouNeedIsCmp>.

=cut

has options => (
  is      => 'rw',
  default => sub { {} },
  coerce  => sub {
    my $orig = shift;
    $orig->{cmp} //= 'Articulate::Sortation::String';
    $orig->{cmp} = instantiate( $orig->{cmp} );
    $orig->{field} //= '/';
    $orig->{field} =~ s~^([^/].*)$~/$1~;
    $orig->{order} //= 'asc';
    return $orig;
  },
);

sub decorate {
  my $self = shift;
  my $item = shift;
  return ( dpath_get( $item->meta, $self->options->{field} ) // '' );
}

sub cmp {
  my $self  = shift;
  my $left  = shift;
  my $right = shift;
  $self->options->{cmp}->cmp( $left, $right );
}

1;
