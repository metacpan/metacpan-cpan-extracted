package Articulate::Sortation::Numeric;
use strict;
use warnings;

use Moo;
with 'Articulate::Role::Sortation::AllYouNeedIsCmp';

=head1 NAME

Articulate::Sortation::Numeric - sort strings using the spaceship
operator

=head1 DESCRIPTION

This implements the L<Articulate::Role::Sortation::AllYouNeedIsCmp>
role to provide a very basic numerical sorter object.

=head1 METHODS

One method provided here, the rest are as in
L<Articulate::Role::Sortation::AllYouNeedIsCmp>.

=head3 cmp

  $self->cmp($a, $b); # returns $a <=> $b

=cut

sub cmp {
  my $self = shift;
  return ( $_[0] <=> $_[1] );
}

=head1 SEE ALSO

=over

=item * L<Articulate::Sortation::String>

=item * L<Articulate::Sortation::Slug>

=back

=cut

1;
