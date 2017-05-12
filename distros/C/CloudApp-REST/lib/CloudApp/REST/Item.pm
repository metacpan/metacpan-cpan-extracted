package CloudApp::REST::Item;

use Moose::Role;

use Carp;
use Readonly;

=head1 NAME

CloudApp::REST::Item - Base class for all items

=cut

use MooseX::Types::DateTimeX qw(DateTime);
use MooseX::Types::URI qw(Uri);

has _REST => (is => 'ro', required => 1, isa => 'CloudApp::REST', clearer => '_remove_REST');

has icon => (is => 'ro', required => 1, isa => Uri, coerce => 1);

has view_counter => (is => 'ro', required => 0, default => 0, isa => 'Int',);
has id           => (is => 'ro', required => 1, isa     => 'Int',);
has owner_id     => (is => 'ro', required => 1, isa     => 'Int',);

has item_type    => (is => 'ro', required => 1, isa => 'Str',);
has name         => (is => 'ro', required => 0, isa => 'Str',);
has private_slug => (is => 'ro', required => 0, isa => 'Str',);
has public_slug  => (is => 'ro', required => 0, isa => 'Str',);

has content_url => (is => 'ro', required => 1, isa => Uri, coerce => 1);
has href        => (is => 'ro', required => 1, isa => Uri, coerce => 1);
has url         => (is => 'ro', required => 1, isa => Uri, coerce => 1);

has created_at => (is => 'ro', required => 1, isa => DateTime, coerce => 1);
has updated_at => (is => 'ro', required => 1, isa => DateTime, coerce => 1);
has deleted_at => (is => 'ro', required => 0, isa => DateTime, coerce => 1);

=head1 SYNOPSIS

This is the base class (a L<Moose role|Moose::Role>) for all items.  You cannot instantiate
L<CloudApp::REST::Item>, so use this as a reference of common attributes and methods.

=head1 ATTRIBUTES

Following attributes are valid for every C<CloudApp::REST::Item::*> instance:

=head2 id

The unique id of the CloudApp item.

=head2 view_counter

The current view count.

=head2 owner_id

The internal CloudApp owner ID.

=head2 item_type

The type of the item.

=head2 name

The given name of the item.

=head2 private_slug

This is the part of the URL after C<http://cl.ly/>, eg. C<TtS> for C<http://cl.ly/TtS>,
if this item is private.

=head2 public_slug

This is the part of the URL after C<http://cl.ly/>, eg. C<58c212593ebb890ebe1f> for C<http://cl.ly/58c212593ebb890ebe1f>,
if this item is public.

=head2 slug

Returns the slug, no matter if it is private or public.

=cut

sub slug {
    my $self = shift;

    return $self->public_slug || $self->private_slug;
}

=head2 content_url

This is the L<URL|URI> of the content, eg. the file itself.

=head2 icon

The L<URL|URI> to the item icon at CloudApp.

=head2 href

The private L<URL|URI> to the item at CloudApp.

=head2 url

The public short L<URL|URI> to the item at CloudApp.

=head2 created_at

The date when this item was uploaded to/created at CloudApp.  Returns a L<DateTime> object.

=head2 updated_at

The date when this item was updated at CloudApp.  If set, returns a L<DateTime> object.

=head2 deleted_at

The date when this item was deleted at CloudApp.  If set, returns a L<DateTime> object.

=head1 SUBROUTINES/METHODS

Following methods are inherited by every C<CloudApp::REST::Item::*> module:

=head2 delete

Deletes the current item at CloudApp.  The item instance can be used after deleting
as long as the instance won't go out of scope, but won't be updated automatically.
CloudApp moves this item to the trash after detelion.

Dies if the item is L</strip>ed.

=cut

sub delete {
    my $self = shift;

    die "This item is stripped, use CloudApp::REST" unless $self->_REST;

    $self->_REST->_delete_item($self);
}

=head2 strip

Removes the reference to L<CloudApp::REST>.

As long as an item is not stripped,
every item instance contains a reference to the API instance, which may also
contain the credentials of the user in cleartext!  Strip an item before you pass
it along to someone else to prevent unwanted or unauthorized reading of the users data!

=cut

sub strip {
    my $self = shift;

    $self->_remove_REST;
    return 1;
}

=head1 SEE ALSO

L<CloudApp::REST>

L<CloudApp::REST::Item::Archive>

L<CloudApp::REST::Item::Audio>

L<CloudApp::REST::Item::Bookmark>

L<CloudApp::REST::Item::Image>

L<CloudApp::REST::Item::Pdf>

L<CloudApp::REST::Item::Text>

L<CloudApp::REST::Item::Unknown>

L<CloudApp::REST::Item::Video>

=head1 AUTHOR

Matthias Dietrich, C<< <perl@rainboxx.de> >>

L<http://www.rainboxx.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Matthias Dietrich.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of CloudApp::REST
