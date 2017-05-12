package Articulate::Caching::Native;
use strict;
use warnings;

use Moo;
use DateTime;
with 'Articulate::Role::Component';

=head1 NAME

Articulate::Caching::Native - cache content in memory

=head1 DESCRIPTION

This implements caching by keeping an hash of the content you wish to
cache in memory.

No attempt is made to monitor the memory size of the hash directly, but
a maximum number of locations under which content may be stored is set.
Once this maximum is reached or exceeded, a quarter of the keys are
removed (preserving those which have most recently been accessed).

Consequently, it is unsuitable for cases where large documents are to
be stored alongside small ones, or where you have a very large number
of locations you want to cache.

=cut

sub _now { DateTime->now . '' }

=head1 ATTRIBUTES

=cut

=head3 cache

This is the contents of the cache. Don't set this.

=cut

has cache => (
  is      => 'rw',
  default => sub { {} },
);

=head3 max_keys

The maximum number of keys in the hash (locations for which either meta
or content or both is stored).

Be warned that each time this is exceeded, a sort is performed on the
values (to find the entries least recently accessed). The larger
max_keys is, the longer this sort will take.

=cut

has max_keys => (
  is      => 'rw',
  default => sub { 255 },
);

=head1 METHODS

=head3 is_cached

  $caching->is_cached( $what, $location )

=cut

sub is_cached {
  my $self     = shift;
  my $what     = shift;
  my $location = shift;
  return undef unless exists $self->cache->{$location};
  return undef unless exists $self->cache->{$location}->{$what};
  return 1;
}

=head3 get_cached

  $caching->get_cached( $what, $location )

=cut

sub get_cached {
  my $self     = shift;
  my $what     = shift;
  my $location = shift;
  return undef unless exists $self->cache->{$location};
  return undef unless exists $self->cache->{$location}->{$what};
  $self->cache->{$location}->{last_retrieved} = _now;
  return $self->cache->{$location}->{$what}->{value};
}

=head3 set_cache

  $caching->set_cache( $what, $location, $value )

=cut

sub set_cache {
  my $self     = shift;
  my $what     = shift;
  my $location = shift;
  my $value    = shift;
  $self->_prune;
  return $self->cache->{$location}->{$what}->{value} = $value;
}

=head3 clear_cache

  $caching->clear_cache( $what, $location )

=cut

sub clear_cache {
  my $self     = shift;
  my $what     = shift;
  my $location = shift;
  return delete $self->cache->{$location}->{$what};
}

=head3 empty_cache

  $caching->empty_cache( $what, $location )

=cut

sub empty_cache {
  my $self = shift;
  delete $self->cache->{$_} for keys %{ $self->cache };
}

sub _prune {
  my $self      = shift;
  my $to_remove = ( keys %{ $self->cache } ) - $self->max_keys;
  if ( $to_remove > 1 ) {
    $to_remove = $to_remove +
      int( $self->max_keys / 4 ); # so we don't have to do this too often
    foreach my $location (
      sort {
        $self->cached->{$a}->{last_retrieved}
          cmp $self->cached->{$b}->{last_retrieved}
      } keys %{ $self->cached }
      )
    {
      delete $self->cached->{$location};
      last unless --$to_remove;
    }
  }
}

1;
