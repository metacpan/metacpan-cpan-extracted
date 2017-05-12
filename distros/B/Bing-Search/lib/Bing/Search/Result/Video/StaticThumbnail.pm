package Bing::Search::Result::Video::StaticThumbnail;
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

Bing::Search::Result::Video::StaticThumbnail - Thumbnails for videos

=head1 METHODS

=over 3

=item C<Width>

The width, in pixels, of the image.

=item C<ContentType>

The type of image.  Sometimes a MIME type ('image/jpeg') sometimes
a simple file extension ('.jpg')

=item C<FileSize>

The size, in bytes, of the image.

=item C<Height>

The height, in pixels, of the image.

=item C<Url>

A L<URI> object representing the URL of the image.

=back

=head1 AUTHOR

Dave Houston, L< dhousotn@cpan.org >, 2010

=head1 LICENSE

This library is free software; you may redistribute and/or modify it under
the same terms as Perl itself.
