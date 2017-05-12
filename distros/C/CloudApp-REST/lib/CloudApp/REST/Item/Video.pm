package CloudApp::REST::Item::Video;

use Moose;
use MooseX::Types::URI qw(Uri);

=head1 NAME

CloudApp::REST::Item::Video - Video item class of CloudApp::REST

=cut

has item_type => (is => 'ro', required => 1, isa => 'Str', default => 'video',);
has remote_url => (is => 'ro', required => 1, isa => Uri, coerce => 1);

with 'CloudApp::REST::Item';

=head1 SYNOPSIS

Video item class of CloudApp::REST.

=head1 ATTRIBUTES

See L<CloudApp::REST::Item> for common attributes and methods of all items.
The attributes listed here are only accessible for video items.

=head2 remote_url

This seems to be the same as the L<CloudApp::REST::Item/content_url>.  Returns an L<URL|URI> instance.

Although most of the items has a remote_url, this attribute is item specific.

=head1 SEE ALSO

L<CloudApp::REST>

L<CloudApp::REST::Item>

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

__PACKAGE__->meta->make_immutable;
