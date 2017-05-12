package Catalyst::Plugin::Upload::Image::Magick::Thumbnail;

use strict;
use warnings;

use Catalyst::Request::Upload;
use Catalyst::Utils;
use Catalyst::Exception;

use File::Temp;
use Image::Magick;

=head1 NAME

Catalyst::Plugin::Upload::Image::Magick::Thumbnail - Making thumbnail image is kept ratio, resized to specified size or less.

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

In your Catalyst project,

  use Catalyst qw/Upload::Image::Magick::Thumbnail/;

You can execute "thumbnail" method in Catalyst::Request::Upload object

  sub resize_to: Local {
    my ($self, $c) = @_;

    my $upload = $c->request->upload('file_field');
    my $thumbnail = $upload->thumbnail({
      density => '60x70',
      format => 'png',
      quality => 100
    });

    # $thumbnail is Image::Magick object
    my ($width, $height) = $thumbnail->Get('width', 'height');

    # ...
  }

=head1 DESCRIPTION

This module is almost same usage L<Image::Magick::Thumbnail>.
But I tried it, I was not able to be satisfied with the result.

In making thumbnail image, it usually is most important that
thumbnail should be stored in the specified size or less.
But L<Image::Magick::Thumbnail> module is wrong about this.

In making thumbnail made by this module, 
it is made to approach the specified size unlimitedly
and kept original ratio.

=head1 METHODS

=head2 thumbnail($args)

Create thumbnail image.

=over 2

=item $args

$args is hash reference.
Please see below arguments detail.

=over 2

=item density

String formatted width x height.
See below example format.

  "80x60"

=item size

Number format similared density option.
The mean if size option value is 60, equal to density option "60x60".
Priority of density option is higher than size option.

=item format

String of image format.
You can choose one of gif, jpg or png.
Default value is jpg.

=item quality

Image quality option. highest value is 100.
minimam value is 0. default 70.

=item gravity

Optional parameter.
Default center. See L<Image::Magick::Thumbnail::Fixed>.

=item compose

Optional parameter.
Default over. See L<Image::Magick::Thumbnail::Fixed>.

=item bgcolor

Optional parameter.
Default white. See L<Image::Magick::Thumbnail::Fixed>.

=back

=back

See also L<Image::Magick::Thumbnail>, L<Image::Magick::Thumbnail::Fixed>

=cut

{

    package Catalyst::Request::Upload;

    sub thumbnail {
        my ( $self, $args ) = @_;

        Catalyst::Exception->throw(
            "Please require Catalyst::Plugin::Upload::Image::Magick")
          unless ( $self->can("is_image") );
        Catalyst::Exception->throw(
            "This file is not image : " . $self->filename )
          unless ( $self->is_image );

        my $density;

        if ( exists $args->{density} ) {
            $density = $args->{density};
        }
        elsif ( exists $args->{size} ) {
            $density = $args->{size} . "x" . $args->{size};
        }
        else {
            $density = "60x60";
        }

        $args->{format} = "jpg" unless ( exists $args->{format} );
        $args->{output} = File::Temp->new(
            DIR => Catalyst::Utils::class2tempdir(
                "Catalyst::Plugin::Upload::Image::Magick::Thumbnail", 1
            ),
            TEMPLATE => "thumbnail_XXXXXX",
            EXT      => $args->{format}
        );

        my $thumbnail = $self->image->Clone;

        my ( $src_width, $src_height ) = $thumbnail->Get( 'width', 'height' );
        my ( $dest_width, $dest_height ) =
          map { s/[^\d]+//g; $_ } split( /x/, $density );

        if ( $src_width * $dest_height - $dest_width * $src_height >= 0 ) {
            $dest_height = ( $dest_width / $src_width ) * $src_height;
        }
        else {
            $dest_width = ( $dest_height / $src_height ) * $src_width;
        }

        $thumbnail->Set(
            quality => ( exists $args->{quality} ) ? $args->{quality} : 70 );
        $thumbnail->Thumbnail( width => $dest_width, height => $dest_height );
        $thumbnail->Write( $args->{format} . ":" . $args->{output} );

				### for File::Temp's cleanup
				$self->{_thumbnail_temp} = {} unless ($self->{_thumbnail_temp});
				$self->{_thumbnail_temp}->{ $thumbnail->Get('filename') } = $args->{output};

        return $thumbnail;
    }
}

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou at cpan.org> >>

=head1 SEE ALSO

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-plugin-upload-image-magick-thumbnail at rt.cpan.org>, or through the web interface at
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

=head1 ACKNOWLEDGEMENTS

=head1 Current Maintainer

The current maintainer of this module is Adam Hopkins. Any questions or comments should be sent to him
at srchulo@cpan.org

=head1 COPYRIGHT & LICENSE

Copyright 2006 Toru Yamaguchi, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Catalyst::Plugin::Upload::Image::Magick::Thumbnail
