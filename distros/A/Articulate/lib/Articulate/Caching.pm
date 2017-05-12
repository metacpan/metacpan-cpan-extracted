package Articulate::Caching;
use strict;
use warnings;

use Moo;
use Articulate::Syntax qw(instantiate_array);
use Articulate::Item;

with 'Articulate::Role::Component';

=head1 NAME

Articulate::Caching - store and retrieve content quickly

=cut

=head1 CONFIGURATION

  components:
    caching:
      Articulate::Caching:
        providers:
        - Articulate::Caching::Native

=head1 ATTRIBUTE

=head3 providers

A list of classes which can be used to cache items.

=cut

has providers => (
  is      => 'rw',
  default => sub { [] },
  coerce  => sub { instantiate_array(@_) }
);

=head1 METHODS

=head3 is_cached

  $caching->is_cached( $what, $location )

=cut

sub is_cached {
  my $self     = shift;
  my $what     = shift;
  my $location = shift;
  foreach my $provider ( @{ $self->providers } ) {
    return 1 if $provider->is_cached( $what, $location );
  }
  return 0;
}

=head3 get_cached

  $caching->get_cached( $what, $location )

=cut

sub get_cached {
  my $self     = shift;
  my $what     = shift;
  my $location = shift;
  foreach my $provider ( @{ $self->providers } ) {
    return $provider->get_cached( $what, $location )
      if $provider->is_cached( $what, $location );
  }
  return undef;
}

=head3 set_cache

  $caching->set_cache( $what, $location, $value )

=cut

sub set_cache {
  my $self     = shift;
  my $what     = shift;
  my $location = shift;
  my $value    = shift;
  foreach my $provider ( @{ $self->providers } ) {
    return $value if $provider->set_cache( $what, $location, $value );
  }
  return undef;
}

=head3 clear_cache

  $caching->clear_cache( $what, $location )

=cut

sub clear_cache {
  my $self     = shift;
  my $what     = shift;
  my $location = shift;
  my $result   = 0;
  foreach my $provider ( @{ $self->providers } ) {
    $result++
      if $provider->clear_cache( $what, $location );
  }
  return $result;
}

=head3 empty_cache

  $caching->empty_cache( )

=cut

sub empty_cache {
  my $self = shift;
  foreach my $provider ( @{ $self->providers } ) {
    $provider->empty_cache();
  }
  return 1;
}

=head1 SEE ALSO

=item * L<Articulate::Caching::Native>

=item * L<Articulate::Storage>

=cut

1;
