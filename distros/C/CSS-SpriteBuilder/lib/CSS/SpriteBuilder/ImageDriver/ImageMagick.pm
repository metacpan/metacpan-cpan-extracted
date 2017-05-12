package CSS::SpriteBuilder::ImageDriver::ImageMagick;

=head1 NAME

CSS::SpriteBuilder::ImageDriver::ImageMagick - Class for image manipulation using Image::Magick module.

=cut

use warnings;
use strict;
use Image::Magick;
use base 'CSS::SpriteBuilder::ImageDriver::Common';

sub driver { 'ImageMagick'                         }
sub width  { $_[0]->{_image}->Get('width')  || 0   }
sub height { $_[0]->{_image}->Get('height') || 0   }

sub reset {
    my ($self, $image) = @_;

    $self->{_image} = $image ? $image->{_image}->Clone() : Image::Magick->new()
        or die "Failed to create image due: $!";

    return;
}

sub read {
    my ($self, $filename) = @_;

    my $error = $self->{_image}->Read($filename);
    die "Failed to read image from '$filename' due: $error" if $error;

    $self->{_image}->Set(type => 'TruecolorMatte');

    return;
}

sub write {
    my ($self, $filename) = @_;

    if ( $self->{_quality} && $filename =~ /\.jpg$/i ) {
        $self->{_image}->Set( quality => $self->{_quality} );
    }

    my $error = $self->{_image}->Write($filename);
    die "Failed to write image to '$filename' due: $error" if $error;

    return;
}

sub set_transparent_color {
    my ($self, $color) = @_;

    $self->{_image}->Transparent(color => $color);

    return;
}

sub extent {
    my ($self, $width, $height) = @_;

    $self->{_image}->Extent(
        width      => $width,
        height     => $height,
        background => 'none',
    );

    return;
}

sub composite {
    my ($self, $image, $x, $y) = @_;

    $self->{_image}->Composite(
        image   => $image->{_image},
        x       => $x,
        y       => $y,
        compose => "over",
    );

    return;
}

1;
