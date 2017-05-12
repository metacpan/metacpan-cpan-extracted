package Articulate::Sortation::String;
use strict;
use warnings;

use Moo;
with 'Articulate::Role::Sortation::AllYouNeedIsCmp';

=head1 NAME

Articulate::Sortation::String - sort strings using perl cmp

=head1 DESCRIPTION

This implements the L<Articulate::Role::Sortation::AllYouNeedIsCmp>
role to provide a very basic string sorter object

=head1 METHODS

One method provided here, the rest are as in
L<Articulate::Role::Sortation::AllYouNeedIsCmp>.

=head3 cmp

  $self->cmp($a, $b); # returns $a cmp $b

=cut

sub cmp {
  my $self = shift;
  return ( $_[0] cmp $_[1] );
}

=head1 SEE ALSO

=over

=item * L<Articulate::Sortation::Slug>

=item * L<Articulate::Sortation::Numeric>

=back

=cut

1;
