package Articulate::Role::Sortation::AllYouNeedIsCmp;
use strict;
use warnings;
use Moo::Role;

=head1 NAME

Articulate::Role::Sortation::AllYouNeedIsCmp - provides sortation methods derived from you cmp method

=head1 SYNOPSIS

  package My::Sortation::Class;
  use Moo;
  with 'Articulate::Role::Sortation::AllYouNeedIsCmp';
  sub cmp { ... }
  sub decorate { ... } # optional
  1;

Provides the C<sort> and C<schwartz> funtions. These call on the C<cmp> method (which you are exected to write) and, optionally, the C<decorate> method (if it exists).

=cut

=head1 METHODS

=head3 order

Convenience method which inspects the C<order> value of the C<options> hash and returns it (or returns C<asc>) if undefined).

=cut

sub order {
  my $self = shift;
  return ( $self->options->{order} // 'asc' ) if $self->can('options');
  return 'asc';
}

=head3 sort

  $sorter->sort( [items] )

Performs a simple sort, using C<cmp> and C<decorate>.

=cut

sub sort {
  my $self  = shift;
  my $items = shift;
  my $dec   = sub {
    my $orig = shift;
    $self->can('decorate')
      ? $self->decorate($orig)
      : $orig;
  };
  return [ sort { $self->cmp( $dec->($b), $dec->($a) ) } @$items ]
    if 'desc' eq $self->order;
  return [ sort { $self->cmp( $dec->($a), $dec->($b) ) } @$items ];
}

=head3 schwartz

  $sorter->schwartz( [items] );

Performs a schwartxian transform using C<decorate>, and sorts the decorated items using C<cmp>, then returns the originals in the sorted order.

=cut

sub schwartz {
  my $self  = shift;
  my $items = shift;
  if ( $self->can('decorate') ) {
    return [
      map { $_->[0] }
      sort { $self->cmp( $a->[1], $b->[1] ) }
      map { [ $_, $self->decorate($_) ] } @$items
    ];
  }
  else {
    return $self->sort($items);
  }
}

1;
