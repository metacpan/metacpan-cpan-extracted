package Acme::DreamyImage;
our $VERSION = '1.1';

use common::sense;
use Object::Tiny qw(seed width height);
use Imager qw(:handy);
use Digest::SHA1 qw(sha1_hex);
use self;

sub new {
    $self = $self->SUPER::new(@args);
    die "'seed'  is required\n" unless defined $self->{seed};
    die "'width' is required, and cannot be 0.\n" unless defined $self->{width} && $self->{width} > 0;
    die "'height' is required, and cannot be 0.\n" unless defined $self->{height} && $self->{height} > 0;

    $self->{seed} = sha1_hex($self->seed);
    return $self;
}

sub write {
    my $image = $self->random_image;
    $image->write(@args) or die $image->errstr;
    return $self;
}

sub random {
    my ($upper_bound) = @args;
    $upper_bound ||= 1;

    $self->{pos} = 0 unless defined($self->{pos});
    my $value = substr($self->{seed}, $self->{pos}, 1);
    $self->{pos} += 1;
    $self->{pos} = 0 if $self->{pos} >= length($self->{seed});
    return int(hex($value) / 15 * $upper_bound);
}

sub random_color {
    return [map { $self->random(255) } 1..4]
}

sub random_background {
    my $image = Imager->new(xsize => $self->width, ysize => $self->height, channels => 3);
    $image->box(filled => 1, color => [255, 255, 255]);
    $image->filter(type => "gradgen",
                   xo => [map { $self->random($self->width)  } 1..2],
                   yo => [map { $self->random($self->height) } 1..2],
                   colors => [ map { $self->random_color } 1..2 ]);

    $image->filter(type => "noise",    subtype => 0, amount => $self->random(10));
    $image->filter(type => "gaussian", stddev  => $self->random( ($self->width + $self->height) / 2 * 0.03 ));

    return $image;
}

sub new_layer {
    my ($xsize, $ysize, $cb) = @_;
    my $layer = Imager->new(xsize => $xsize, ysize => $ysize, channels => 4);
    $cb->($layer);
    return $layer;
}

sub random_image {
    my $image = $self->random_background;
    my $xsize = $self->width;
    my $ysize = $self->height;
    my $resize = 0;

    if ($xsize < 128) {
        $resize = 1;
        $xsize = 128;
    }

    if ($ysize < 128) {
        $resize = 1;
        $ysize = 128;
    }

    # Big Blur Circles
    new_layer(
        $xsize, $ysize,
        sub {
            my ($layer) = @_;
            my $layer = Imager->new(xsize => $xsize, ysize => $ysize, channels => 4);
            $layer->filter(type => "noise", subtype => 0, amout => 20);
            for my $size (map { ($xsize + $ysize) / 16 + $_ } 1..20) {
                my ($x, $y) = ($self->random($xsize), $self->random($ysize));
                $layer->circle(fill => { solid   => [255, 255, 255, $self->random(30) + 10],  combine => "add" }, x => $x, y => $y, r => $size);
            }
            $layer->filter(type => "gaussian", stddev => $self->random(30));

            $image->compose(src => $layer, tx => 0, ty => 0, combine => 'add');
        }
    );

    # Big Blur Boxes
    new_layer(
        $xsize, $ysize,
        sub {
            my ($layer) = @_;
            for my $size (map {  ($xsize + $ysize) / 16 + $_ } 1..20) {
                my ($x, $y) = ($self->random($xsize), $self->random($ysize));
                $layer->box(fill => { solid   => [255, 255, 255, $self->random(30) + 10],  combine => "add" },
                            xmin => $x, ymin => $y,
                            xmax => $x + $size, ymax => $y + $size);
            }
            $layer->filter(type => "noise", amount => $self->random(($xsize + $ysize) /2 * 0.03 ), subtype => 1);
            $layer->filter(type => "gaussian", stddev => $self->random(30));

            $image->compose(src => $layer, tx => 0, ty => 0, combine => 'add');
        }
    );

    # Small Sharp Circles
    for (1..10+$self->random(20)) {
        my $size = $self->random( ($xsize + $ysize) / 2 / 16);
        my ($x, $y) = ($self->random($xsize), $self->random($ysize));
        my $opacity = $self->random(30) + 10;
        $image->circle(fill => { solid => [255, 255, 255, $opacity], combine => "add" },  x => $x, y => $y, r => $size);
    }

    if ($resize) {
        $image = $image->scale(type => "nonprop", xpixels => $self->width, ypixels => $self->height);
    }

    return $image;
}


1;
__END__

=head1 NAME

Acme::DreamyImage - Dreamy image generator

=head1 SYNOPSIS

  use Acme::DreamyImage;

  my $img = Acme::DreamyImage->new(seed => $_, width => 1024, height => 768);

  $img->write(file => "nice_background.png");

=head1 DESCRIPTION

Acme::DreamyImage is a image generator that produce dreamy-looking images.

=head1 AUTHOR

Kang-min Liu E<lt>gugod@gugod.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Kang-min Liu C<< <gugod@gugod.org> >>.

This is free software, licensed under:

    The MIT (X11) License

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

