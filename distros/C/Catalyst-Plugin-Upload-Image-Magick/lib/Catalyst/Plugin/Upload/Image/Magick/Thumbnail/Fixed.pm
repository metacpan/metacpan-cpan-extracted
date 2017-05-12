package Catalyst::Plugin::Upload::Image::Magick::Thumbnail::Fixed;

use strict;
use warnings;

use Catalyst::Request::Upload;
use Catalyst::Utils;
use Catalyst::Exception;

use File::Temp;
use Image::Magick;
use Image::Magick::Thumbnail::Fixed;

=head1 NAME

Catalyst::Plugin::Upload::Image::Magick::Thumbnail::Fixed - Making thumbnail image is kept ratio in fixed size image.

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

In your Catalyst project,

  use Catalyst qw/Upload::Image::Magick::Thumbnail::Fixed/;

You can execute "thumbnail_fixed" method in Catalyst::Request::Upload object

  sub resize_to: Local {
    my ($self, $c) = @_;

    my $upload = $c->request->upload('file_field');
    my $thumbnail = $upload->thumbnail_fixed({
      density => '60x70',
      format => 'png',
      quality => 100
    });

    # $thumbnail is Image::Magick object
    my ($width, $height) = $thumbnail->Get('width', 'height');

    # ...
  }


=head1 METHODS

=head2 thumbnail_fixed($args)

Create "fixed" size thumbnail image.

=over 2

=item $args

$args is hash reference.
Please see below arguments detail.

=over 2

=item density

String formatted width x height.
See below example format.

  "80x60"

=item width

Number format of thumbnail width.
Priority of density option is higher than width option.
Default value is 60pixel.

=item height

Number format of thumbnail height.
Priority of density option is higher than height option.
Default value is 60pixel.

=item format

String of image format.
You can choose one of gif, jpg or png.

=item quality

Image quality option. highest value is 100.
minimam value is 0. default 70.

=back

=back

See also L<Image::Magick::Thumbnail>, L<Image::Magick::Thumbnail::Fixed>


=cut

{

    package Catalyst::Request::Upload;

    sub thumbnail_fixed {
        my ( $self, $args ) = @_;

        Catalyst::Exception->throw(
            "Please require Catalyst::Plugin::Upload::Image::Magick")
          unless ( $self->can("is_image") );
        Catalyst::Exception->throw(
            "This file is not image : " . $self->filename )
          unless ( $self->is_image );

        unless ( $self->{_thumbnail_fixed} ) {
            $self->{_thumbnail_fixed} = Image::Magick::Thumbnail::Fixed->new;
        }

        if ( exists $args->{density} && $args->{density} =~ m|\d+x\d+| ) {
            ( $args->{width}, $args->{height} ) =
              map { s/\s+//g; $_ } split( /x/, $args->{density} );
            delete $args->{density};
        }
        else {
            $args->{width}  = 60 unless ( exists $args->{width} );
            $args->{height} = 60 unless ( exists $args->{height} );
        }

        $args->{format} = "jpg" unless ( exists $args->{format} );
        $args->{input}  = $self->tempname;
        $args->{output} = File::Temp->new(
            DIR => Catalyst::Utils::class2tempdir(
                "Catalyst::Plugin::Upload::Image::Magick::Thumbnail::Fixed", 1
            ),
            TEMPLATE => "thumbnail_XXXXXX",
            EXT      => $args->{format}
        );

        eval { $self->{_thumbnail_fixed}->thumbnail(%$args); };
        if ($@) {
            Catalyst::Exception->throw($@);
        }
        elsif ( !-e $args->{output} ) {
            Catalyst::Exception->throw(
                "Can't create thumbnail : " . $args->{output} );
        }

        my $thumb = Image::Magick->new;
        $thumb->Read( $args->{output} );

				### for File::Temp's cleanup
				$self->{_thumbnail_temp} = {} unless ($self->{_thumbnail_temp});
				$self->{_thumbnail_temp}->{ $thumb->Get('filename') } = $args->{output};


        return $thumb;
    }

}

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou at cpan.org> >>

=head1 SEE ALSO

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-plugin-upload-image-magick-thumbnail-fixed at rt.cpan.org>, or through the web interface at
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

1;    # End of Catalyst::Plugin::Upload::Image::Magick::Thumbnail::Fixed
