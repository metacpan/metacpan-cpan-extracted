package CSS::SpriteBuilder::ImageDriver::Fake;

=head1 NAME

CSS::SpriteBuilder::ImageDriver::Fake - Fake class.

=cut

use warnings;
use strict;
use base 'CSS::SpriteBuilder::ImageDriver::Common';

sub new {
    my ($class, @args) = @_;

    my $self = $class->SUPER::new(
        _width  => 0,
        _height => 0,
        @args,
    );

    return $self;
}

sub width          { $_[0]->{_width}  }
sub height         { $_[0]->{_height} }

sub reset {
    my ($self, $image) = @_;

    if ($image) {
        $self->{_width}  = $image->width();
        $self->{_height} = $image->height();
    }
    else {
        $self->{_width} = $self->{_height} = 0;
    }

    return;
}

sub read {
    my ($self, $filename) = @_;

    $self->{_width} = $self->{_height} = 32;

    return;
}

sub write {
    my ($self, $filename) = @_;

    open(my $fh, '>', $filename) or die "Failed to open file '$filename' due: $!";
    binmode $fh;
    print $fh "Fake";
    close $fh or die "Failed to close file '$filename' due: $!";

    return;
}

sub extent {
    my ($self, $width, $height) = @_;

    $self->{_width}  = $width;
    $self->{_height} = $height;

    return;
}

sub composite {
    #Nothing
}

1;
