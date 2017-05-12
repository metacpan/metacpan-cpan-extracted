package Data::Petitcom::Resource::COL;

use strict;
use warnings;

use parent qw{ Data::Petitcom::Resource };

use bytes ();
use Data::Petitcom::PTC;
use Data::Petitcom::BMP qw{ Load Dump RGB555toRGB888 RGB888toRGB555 };

use constant RESOUECE            => 'COL';
use constant PTC_OFFSET_DATA     => 0x0C;
use constant PTC_COLORMAP_LENGTH => 512;     # RGB555(16bit) x 256colors
use constant COLORMAP_COLS       => 16;
use constant PTC_NAME            => 'DPTC_COL';

sub save {
    my $self = shift;
    my %opts = @_;
    my $name = delete $opts{name};
    my $ptc  = Data::Petitcom::PTC->new(
        resource => RESOUECE,
        name     => $name || PTC_NAME,
        version  => 'PETC0100',
    );
    my $bmp    = Load( $self->data );
    my $rgb555 = RGB888toRGB555( $bmp->{colormap} );
    $ptc->data( pack 'v*', @$rgb555 );
    return $ptc;
}

sub load {
    my $self = shift;
    my $ptc  = shift;
    my $raw_colormap
        = bytes::substr( $ptc->data, PTC_OFFSET_DATA, PTC_COLORMAP_LENGTH );
    my @rgb555  = unpack 'v*', $raw_colormap;    # LE-short
    my $rgb888  = RGB555toRGB888(@rgb555);
    my $raw_bmp = Dump(
        width    => COLORMAP_COLS,
        height   => COLORMAP_COLS,
        colormap => $rgb888,
        pixels => [ map {
            ( (COLORMAP_COLS - 1) - int( $_ / COLORMAP_COLS ) ) * COLORMAP_COLS + $_ % COLORMAP_COLS
        } ( 0 .. 255 ) ],
    );
    $self->data($raw_bmp);
    return $self;
}

1;
