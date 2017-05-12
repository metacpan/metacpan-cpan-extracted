package Articulate::Role::Storage;
use strict;
use warnings;
use Moo::Role;

=head1 NAME

Articulate::Role::Storage - caching functions

=head1 DESCRIPTION

This role provides retrieval methods which look for cached versions of
the content desired before falling back to the canonical retrieval.

=cut

=head1 METHODS

=cut

=head3 get_content_cached

  $self->get_content_cached( $location );

=cut

sub get_content_cached {
  my $self     = shift;
  my $location = shift->location;
  my $caching  = $self->caching;
  if ( $caching->is_cached( content => $location ) ) {
    return $caching->get_cached( content => $location );
  }
  my $content = $self->get_content($location);
  $caching->set_cache( content => $location, $content );
  return $content;
}

=head3 get_meta_cached

  $self->get_meta_cached( $location );

=cut

sub get_meta_cached {
  my $self     = shift;
  my $location = shift->location;
  my $caching  = $self->caching;
  if ( $caching->is_cached( meta => $location ) ) {
    return $caching->get_cached( meta => $location );
  }
  my $meta = $self->get_meta($location);
  $caching->set_cache( meta => $location, $meta );
  return $meta;
}

around set_content => sub {
  my ( $orig, $self ) = ( shift, shift );
  my $return = $self->$orig(@_);
  $self->caching->set_cache( content => $_[0], $return );
  return $return;
};

around set_meta => sub {
  my ( $orig, $self ) = ( shift, shift );
  my $return = $self->$orig(@_);
  $self->caching->set_cache( meta => $_[0], $return );
  return $return;
};

around delete_item => sub {
  my ( $orig, $self ) = ( shift, shift );
  my $return = $self->$orig(@_);
  $self->caching->clear_cache( meta    => $_[0] );
  $self->caching->clear_cache( content => $_[0] );

  # what about children?
  # Three possible approaches:
  # 1. clear cache of anything that looks le it might be a child
  # 2. storage deletion should recursively delete for all children
  # 3. storage should return an arrayref of items it deleted
  return $return;
};

around empty_all_content => sub {
  my ( $orig, $self ) = ( shift, shift );
  my $return = $self->$orig(@_);
  $self->caching->empty_cache();
  return $return;
};

1;
