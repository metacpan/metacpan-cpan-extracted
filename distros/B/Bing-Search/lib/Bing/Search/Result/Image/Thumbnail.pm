package Bing::Search::Result::Image::Thumbnail;
use Moose;

extends 'Bing::Search::Result';

with 'Bing::Search::Role::Types::UrlType';

with 'Bing::Search::Role::Result::Width';
with 'Bing::Search::Role::Result::ContentType';
with 'Bing::Search::Role::Result::FileSize';
with 'Bing::Search::Role::Result::Height';
with 'Bing::Search::Role::Result::Url';

__PACKAGE__->meta->make_immutable;

=head1 NAME

Bing::Search::Result::Image::Thumbnail - A thumbnail image

=head1 METHODS

=over 3

=item C<Width>

The width, in pixels.

=item C<ContentType>

The type of image.  MIME or not.

=item C<FileSize>

The size, in bytes.

=item C<Height>

The height, in pixels.

=item C<Url>

A L<URI> object representing the thumbnail's URL.

=back

=head1 AUTHOR

Dave Houston, L< dhoustoncpan.org >, 2010

=head1 LICENSE

This library is free software; you may redistribute and/or modify it under
the same terms as Perl itself.
