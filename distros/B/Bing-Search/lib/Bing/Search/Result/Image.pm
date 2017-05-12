package Bing::Search::Result::Image;
use Moose;
use Bing::Search::Result::Image::Thumbnail;

extends 'Bing::Search::Result';

with 'Bing::Search::Role::Types::UrlType';

with 'Bing::Search::Role::Result::Width';
with 'Bing::Search::Role::Result::FileSize';
with 'Bing::Search::Role::Result::DisplayUrl';
with 'Bing::Search::Role::Result::Height';
with 'Bing::Search::Role::Result::MediaUrl';
with 'Bing::Search::Role::Result::Title';
with 'Bing::Search::Role::Result::ContentType';
with 'Bing::Search::Role::Result::Url';


has 'Thumbnail' => ( is => 'rw', isa => 'Bing::Search::Result::Image::Thumbnail' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $t = Bing::Search::Result::Image::Thumbnail->new;
   my $thumbdata = delete $data->{Thumbnail};
   $t->data( $thumbdata );
   $t->_populate();
   $self->Thumbnail( $t );
};

__PACKAGE__->meta->make_immutable;

=head1 NAME

Bing::Search::Result::Image - An image result

=head1 METHODS

=over 3

=item C<Width>

The width, in pixels, of the image.

=item C<Height> 

The height, in pixels, of the image.

=item C<FileSize>

The size, in bytes, of the image.

=item C<DisplayUrl>

A L<URI> object containing the URL (possibly modified for display) 
typically used to display the full-sized image.

=item C<MediaUrl>

A L<URI> object containing the URL typically used to display the
full-sized image.

=item C<ContentType>

The type of image, usually simply the file extension, though may 
also be a MIME type notation.  

=item C<Title>

A string containing the title of the image.

=item C<Url>

A L<URI> object containing the URI to the image.

=item C<Thumbnail>

Returns a L<Bing::Search::Result::Image::Thumbnail> object.  It is very 
similar to this object.  A thumbnail has a B<Width> and B<Height>, a
B<ContentType>, a B<FileSize>, and a B<Url>, all of which describe
the thumbnail instead of the full-sized image.

=back
