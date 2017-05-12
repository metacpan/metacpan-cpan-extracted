package Articulate::Service::Simple;

use strict;
use warnings;
use Articulate::Syntax;

use Moo;
with 'Articulate::Role::Service';

use Try::Tiny;
use Scalar::Util qw(blessed);

=head1 NAME

Articulate::Service::Simple - provide create, read, update, delete

=cut

=head1 METHODS

=head3 handle_create


  create => {
    meta     => {}
    content  => '...',
    location => '...'
  }

Creates new content. Throws an error if the content already exists or
if the user has no write permission on that location.

=head3 handle_read

  read => {
    location => '...'
  }

Retrieves the content at that location. Throws an error if the content
does not exist or if the user has no read permission on that location.

=head3 handle_update

  update => {
    meta     => {}
    content  => '...',
    location => '...'
  }

Updates the content at that location. Throws an error if the content
does not exist or if the user has no write permission on that location.

=head3 handle_delete

  delete => {
    location => '...'
  }

Deletes the content at that location. Throws an error if the content
does not exist or if the user has no write permission on that location.

=cut

sub handle_create {
  my $self    = shift;
  my $request = shift;
  my $item =
    blessed $request->data ? $request->data : $self->construction->construct(
    {
      meta => {},
      ( %{ $request->data } ? %{ $request->data } : () ),
    }
    );
  my $location = $item->location;

  my $user = $request->user_id;
  my $permission = $self->authorisation->permitted( $user, write => $location );
  if ($permission) {

    throw_error 'AlreadyExists' if $self->storage->item_exists($location);

    $self->validation->validate($item)
      or throw_error BadRequest => 'The content did not validate';
    $self->enrichment->enrich( $item, $request ); # this will throw if it fails
    $self->storage->create_item($item);           # this will throw if it fails

    my $item_class = $item->location->[-2];
    $self->augmentation->augment($item);          # this will throw if it fails

    return new_response $item_class, {
      $item_class => {
        schema   => $item->meta->{schema},
        content  => $item->content,
        location => $item->location,              # as string or arrayref?
      },
    };
  }
  else {
    throw_error Forbidden => $permission->reason;
  }

}

sub handle_read {
  my $self       = shift;
  my $request    = shift;
  my $location   = new_location $request->data->{location};
  my $user       = $request->user_id;
  my $permission = $self->authorisation->permitted( $user, read => $location );
  if ($permission) {
    throw_error 'NotFound' unless $self->storage->item_exists($location);
    my $item = $self->construction->construct(
      {
        meta     => $self->storage->get_meta_cached($location),
        content  => $self->storage->get_content_cached($location),
        location => $location,
      }
    );

    my $item_class = $item->location->[-2];

    $self->augmentation->augment($item); # or throw

    return new_response $item_class => {
      $item_class => {
        schema  => $item->meta->{schema},
        content => $item->content,
      },
    };
  }
  else {
    return throw_error Forbidden => $permission->reason;
  }
}

sub handle_update {
  my $self    = shift;
  my $request = shift;

  my $item =
    blessed $request->data ? $request->data : $self->construction->construct(
    {
      meta => {},
      ( %{ $request->data } ? %{ $request->data } : () ),
    }
    );
  my $location = $item->location;

  my $user = $request->user_id;
  my $permission = $self->authorisation->permitted( $user, write => $location );
  if ($permission) {

    throw_error 'NotFound' unless $self->storage->item_exists($location);

    $self->validation->validate($item)
      or throw_error BadRequest => 'The content did not validate'; # or throw
    $self->enrichment->enrich( $item, $request ); # this will throw if it fails
    $self->storage->set_meta($item)    or throw_error 'Internal'; # or throw
    $self->storage->set_content($item) or throw_error 'Internal'; # or throw

    my $item_class = $item->location->[-2];
    $self->augmentation->augment($item) or throw_error 'Internal'; # or throw

    return new_response $item_class, {
      $item_class => {
        schema   => $item->meta->{schema},
        content  => $item->content,
        location => $item->location,      # as string or arrayref?
      },
    };
  }
  else {
    return throw_error Forbidden => $permission->reason;
  }

}

sub handle_delete {
  my $self    = shift;
  my $request = shift;

  my $location = new_location $request->data->{location};

  my $user = $request->user_id;
  my $permission = $self->authorisation->permitted( $user, write => $location );
  if ($permission) {
    throw_error 'NotFound' unless $self->storage->item_exists($location);
    $self->storage->delete_item($location) or throw_error 'Internal'; # or throw
    return new_response 'success', {};
  }
  else {
    return throw_error Forbidden => $permission->reason;
  }

}

1;
