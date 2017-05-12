package Articulate::Service::SimpleForms;

use strict;
use warnings;

use Articulate::Syntax;

use Moo;
with 'Articulate::Role::Service';

use Try::Tiny;
use Scalar::Util qw(blessed);

sub handle_create_form {
  my $self       = shift;
  my $request    = shift;
  my $user       = $request->user_id;
  my $location   = new_location $request->data->{location};
  my $permission = $self->authorisation->permitted( $user, write => $location );

  if ($permission) {

    return new_response 'form/create', {
      form => {
        location => new_location $location, # as string or arrayref?
      },
    };
  }
  else {
    throw_error Forbidden => $permission->reason;
  }

}

sub handle_upload_form {
  my $self       = shift;
  my $request    = shift;
  my $user       = $request->user_id;
  my $location   = new_location $request->data->{location};
  my $permission = $self->authorisation->permitted( $user, write => $location );

  if ($permission) {

    return new_response 'form/upload', {
      form => {
        location => new_location $location, # as string or arrayref?
      },
    };
  }
  else {
    throw_error Forbidden => $permission->reason;
  }
}

sub handle_edit_form {
  my $self    = shift;
  my $request = shift;

  my $location   = new_location $request->data->{location};
  my $user       = $request->user_id;
  my $permission = $self->authorisation->permitted( $user, write => $location );

  if ($permission) {

    throw_error 'NotFound' unless $self->storage->item_exists($location);

    my $item = $self->storage->get_item($location);

    # we don't want to interpret at this point

    return new_response 'form/edit', {
      raw => {
        meta     => $item->meta,
        content  => $item->content,
        location => $item->location, # as string or arrayref?
      },
    };
  }
  else {
    throw_error Forbidden => $permission->reason;
  }

}

sub handle_delete_form {
  my $self    = shift;
  my $request = shift;

  my $item       = $request->data;
  my $location   = $item->location;
  my $user       = $request->user_id;
  my $permission = $self->authorisation->permitted( $user, write => $location );

  if ( $self->authorisation->permitted( $user, write => $location ) ) {
    throw_error 'NotFound' unless $self->storage->item_exists($location);

    my $item       = $self->storage->get_item($location);
    my $item_class = $item->location->[-2];
    $self->augmentation->augment($item) or throw_error 'Internal'; # or throw

    return new_response 'form/delete', {
      $item_class => {
        schema   => $item->meta->{schema},
        content  => $item->content,
        location => $item->location,      # as string or arrayref?
      },
    };
  }
  else {
    throw_error Forbidden => $permission->reason;
  }

}

1;
