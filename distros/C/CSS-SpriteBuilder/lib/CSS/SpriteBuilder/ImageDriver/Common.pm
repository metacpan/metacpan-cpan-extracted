package CSS::SpriteBuilder::ImageDriver::Common;

=head1 NAME

CSS::SpriteBuilder::Image::Common - Abstract class for image manipulation

head1 SYNOPSIS

    my $image = SpriteBuilder::ImageDriver::<driver>->new();

    $image->read('image.png');

    $image->extent( $image->width() * 2, $image->height() * 2);

    $image->write('image2.png');

=head1 METHODS

=head2 new

    my $image = SpriteBuilder::ImageDriver::<driver>->new();

Creates a new blank image.

=back

=head2 driver

Returns a driver name (ImageMagick, GD or undef).

=back

=head2 width

Returns a width of image.

=back

=head2 height

Returns a height of image.

=back

=head2 is_blank

Returns '1' when image is blank.

=back

=head2 reset([<image>])

Make a blank image.
When B<image> parameter is specified than assign the initial value as B<image>.

=back

=head2 set_transparent_color(<color>)

$image->set_transparent_color('white');

Set transparent color.

=back

=head2 set_quality(<0..100>)

Set image qualit (for JPEG only).

=back

=head2 read(<filename>)

Reads an image from a file.

=back

=head2 write(<filename>)

Writes the image to a file.

=back

=head2 extent(<width>, <height>)

Extent image to B<width> x B<height>.

=back

=head2 composite(<image>, <x>, <y>)

Composite image, specified by B<image> parameter, onto source image.

=back

=cut

use warnings;
use strict;
use Scalar::Util qw(blessed);

sub new {
    my ($class, @args) = @_;

    my $self = bless {
        _image   => undef,
        _quality => undef,
        @args,
    }, $class;

    $self->reset();

    return $self;
}

sub driver   { undef                  }
sub width    { 0                      }
sub height   { 0                      }
sub is_blank { $_[0]->width() ? 0 : 1 }

sub reset {
    my ($self, $image) = @_;

    # Nothing

    return;
}

sub set_transparent_color {
    my ($self, $color) = @_;

    # Nothing

    return;
}

sub set_quality {
    my ($self, $quality) = @_;

    $self->{_quality} = $quality;

    return;
}

sub read {
    my ($self, $filename) = @_;

    die "Not implemented";
}

sub write {
    my ($self, $filename) = @_;

    die "Not implemented";
}

sub extent {
    my ($self, $width, $height) = @_;

    die "Not implemented";
}

sub composite {
    my ($self, $image, $x, $y) = @_;

    die "Not implemented";
}

1;
