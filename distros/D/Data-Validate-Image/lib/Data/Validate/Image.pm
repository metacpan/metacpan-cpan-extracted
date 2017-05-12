package Data::Validate::Image;
use strict;
use warnings;

our $VERSION = '0.012002';
$VERSION = eval $VERSION;

use Image::Info;

sub new{
    my $incovant = shift;
    my $class = ref( $incovant ) || $incovant;

    my $self = {};
    bless( $self, $class );

    return $self;
}

sub validate{
    my ( $self, $file ) = @_;

    my $image_type = Image::Info::image_info($file);

    if ( !defined( $image_type->{'file_ext'} ) ){
        return undef;
    }

    my $image_info = {
        'width' => $image_type->{'width'},
        'height' => $image_type->{'height'},
        'size' => (-s $file) / 1024,
        'mime' => $image_type->{'file_media_type'},
        'file_ext' => $image_type->{'file_ext'},
    };

    if ( $self->_convert_installed ){ #test if imagemagic is installed
        my @frames = `convert -identify '${file}' null: 2> /dev/null`;

        $image_info->{'frames'} = scalar( @frames );
        $image_info->{'animated'} = ($#frames) ? 1 : 0;

        if ( $? ){
        # convert returns 0 on success - prolly a corrupt image
            return undef;
        }
    }

    return $image_info;
}

sub _convert_installed{
    my ( $self ) = @_;

    my @paths = split( /:|;/, $ENV{PATH} );
    foreach my $path ( @paths ){
        if (
            ( -e "${path}/convert" )
            && ( -x "${path}/convert" )
        ){
            return 1;
        }
    }

    return 0;
}

1;

=head1 NAME

Data::Validate::Image - Validates an image and returns basic info

=head1 SYNOPSIS

    use Data::Validate::Image;

    my $validator = Data::Validate::Image->new();
    my $image_info = $validator->validate( '/path/to/image' );

    if ( defined( $image_info ) ){
        #valid image, do things here
    } else {
        #invalid image
    }

=head1 DESCRIPTION

A simple image validator class, which provides a single C<validate> method
that upon success returns a hash ref of image properties:

  {
    'width'    => 'image width',
    'height'   => 'image height',
    'size'     => 'image filesize (KB)',
    'mime'     => 'image mime type',
    'file_ext' => '*correct* file extenstion',
    'frames'   => 'frame count', # requires convert from ImageMagick
    'animated' => 1 || 0,        # requires convert from ImageMagick
  }

For invalid images the C<validate> method returns C<undef>.

=head2 IMPORTANT

B<REQUIRES> convert (from L<ImageMagick|http://www.imagemagick.org/>) to
detect the C<frames> and C<animated> properties.

I used convert over PerlMagick because I found PerlMagick to be very
unstable.

=head1 METHODS

=head2 validate

    Returns image properties for valid image or C<undef> for invalid image

=head1 AUTHOR

Mark Ellis E<lt>markellis@cpan.orgE<gt>

=head1 CONTRIBUTORS

j1n3l0 - Nelo Onyiah - E<lt>nelo.onyiah@gmail.comE<gt>

=head1 SEE ALSO

L<Image::Info>

=head1 LICENSE

Copyright 2015 Mark Ellis E<lt>markellis@cpan.orgE<gt>

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
