package Articulate::Service::SimplePreviews;

use strict;
use warnings;

use Articulate::Syntax;

use Moo;
with 'Articulate::Role::Service';

use Try::Tiny;
use Scalar::Util qw(blessed);

=head1 NAME

Articulate::Service::SimplePreviews - provide preview

=cut

=head1 METHODS

=head3 handle_preview

  preview => {
    meta     => {}
    content  => '...',
    location => '...'
  }

This is in almost all respects identical to the C<create> verb in
L<Articulate::Service::Simple> with the exception that nothing is
written.

Throws an error if the content already exists or if the user has no
write permission on that location.

=cut

sub handle_preview {
  my $self    = shift;
  my $request = shift;

  my $item =
    blessed $request->data
    ? $request->data
    : $self->construction->construct(
    { ( %{ $request->data } ? %{ $request->data } : () ), } );

  my $location = $item->location;

  my $user = $request->user_id;
  my $permission = $self->authorisation->permitted( $user, write => $location );

  if ($permission)
  { # no point offering this service to people who can't write there

    $self->validation->validate($item)
      or throw_error BadRequest => 'The content did not validate'; # or throw
    $self->enrichment->enrich( $item, $request ); # this will throw if it fails

    # skip the storage interaction
    my $item_class = $item->location->[-2];

    $self->augmentation->augment($item_class);    # this will throw if it fails

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

1;
