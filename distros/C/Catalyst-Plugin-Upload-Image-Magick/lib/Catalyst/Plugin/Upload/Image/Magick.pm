package Catalyst::Plugin::Upload::Image::Magick;

use strict;
use warnings;

use Catalyst::Request::Upload;
use Catalyst::Exception;

use Image::Magick;

=head1 NAME

Catalyst::Plugin::Upload::Image::Magick - Image information plugin for Catalyst::Request::Upload

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

In your L<Catalyst> project, 

  use Catalyst qw/Upload::Image::Magick/;

And you can execute method around image information in L<Catalyst::Request::Image> object;

  sub uploaded_action: Local {
    my ($self, $c) = shift;

    $upload = $c->request->upload('file_field');

    if ($upload->is_image) {
      $c->log->debug("width : " . $upload->width);
      $c->log->debug("height : " . $upload->height);
    }

    # ...
  }

=cut

{

    package Catalyst::Request::Upload;

    sub image {
        my $self = shift;

        unless ( $self->{_image} ) {
            my $image = Image::Magick->new;

            return undef if ( !$self->type || [ split( '/', $self->type ) ]->[0] ne 'image' );
            my $result = $image->Read( file => $self->fh );
            Catalyst::Exception->throw($result) if ($result);

            $self->{_image} = $image;
        }

        return $self->{_image};
    }

    sub is_image {
        my $self = shift;

        return ( $self->image ) ? 1 : 0;
    }

    for my $method (qw/width height/) {
        no strict 'refs';

        *{$method} = sub {
            my $self = shift;

            return $self->image->get($method) if ( $self->image );
            return undef;
        };
    }
}

=head1 METHODS

=head2 image()

If uploaded file is image, then return L<Image::Magick> object, 
is't image then throw L<Catalyst::Exception>.

=head2 is_image()

If uploaded file is image, then return 1, else 0.

=head2 width()

If uploaded file is image, then return image width, else undef.

=head2 height()

If uploaded file is image, then return image height, else undef.

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou at cpan.org> >>

=head1 SEE ALSO

=over 2

=item L<Catalyst>

=item L<Catalyst::Request::Upload>

=item L<Image::Magick>

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-plugin-upload-image-magick at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Plugin-Upload-Image-Magick>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Plugin::Upload::Image::Magick

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Plugin-Upload-Image-Magick>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Plugin-Upload-Image-Magick>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-Upload-Image-Magick>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Plugin-Upload-Image-Magick>

=back

=head1 Current Maintainer

The current maintainer of this module is Adam Hopkins. Any questions or comments should be sent to him
at srchulo@cpan.org

=head1 COPYRIGHT & LICENSE

Copyright 2006 Toru Yamaguchi, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Catalyst::Plugin::Upload::Image::Magick
