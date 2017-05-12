package Articulate::Service::List;

use strict;
use warnings;

use Articulate::Syntax;
use Articulate::Sortation::MetaDelver;

# The following provide objects which must be created on a per-request basis
use Articulate::Request;
use Articulate::Response;

use Moo;
with 'Articulate::Role::Service';

use Try::Tiny;
use Scalar::Util qw(blessed);

sub handle_list {
  my $self    = shift;
  my $request = shift;

  my $location = new_location $request->data->{location};
  my $sort     = $request->data->{sort}
    ; # needs careful validation as this can do all sorts of fun constructor logic

  my $user = $request->user_id;
  my $permission = $self->authorisation->permitted( $user, read => $location );

  if ($permission) {
    my $items = [];
    foreach my $item_location ( map { new_location "$location/$_" }
      $self->storage->list_items($location) )
    {
      if ( $self->authorisation->permitted( $user, read => $item_location ) ) {
        my $item = $self->construction->construct(
          {
            location => $item_location,
            meta     => $self->storage->get_meta($item_location),
            content  => $self->storage->get_content($item_location),
          }
        );
        $self->augmentation->augment($item); # this will throw if it fails
        push @$items, $item;
      }
    }
    my $sorter = Articulate::Sortation::MetaDelver->new($sort);
    return new_response 'list', {
      list => [
        map {
          {
            is       => $_->location->[-2],
            location => $_->location,
            schema   => $_->meta->{schema},
            content  => $_->content,
          }
        } @{ $sorter->schwartz($items) }
      ],
    };
  }
  else {
    throw_error 'Forbidden' => $permission->reason;
  }

}

1;
