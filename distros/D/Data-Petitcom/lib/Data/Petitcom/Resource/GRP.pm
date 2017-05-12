package Data::Petitcom::Resource::GRP;

use strict;
use warnings;

use parent qw{ Data::Petitcom::Resource };

use bytes ();
use Data::Petitcom::PTC;
use Data::Petitcom::BMP qw{ Load BMP2DATA DATA2BMP };

use constant RESOURCE   => 'GRP';
use constant BMP_WIDTH  => 256;
use constant BMP_HEIGHT => 192;
use constant PTC_NAME   => 'DPTC_GRP';

sub data {
    my $self  = shift;
    if (my $raw_bmp = shift) {
        my $bmp = Load($raw_bmp);
        Carp::croak "unsupported width x height: $bmp->{width} x $bmp->{height}"
            if (   $bmp->{width} != $self->BMP_WIDTH()
                || $bmp->{height} != $self->BMP_HEIGHT() );
        $self->{data} = $raw_bmp;
    }
    return $self->{data};
}

sub save {
    my $self = shift;

    my %opts     = @_;
    my $name     = delete $opts{name} || $self->PTC_NAME();
    my $sp_width = ( $self->RESOURCE() eq 'GRP' )
        ? 64
        : delete $opts{sp_width} || 16;
    my $sp_height = ( $self->RESOURCE() eq 'GRP' )
        ? 64
        : delete $opts{sp_height} || 16;


    my $ptc = Data::Petitcom::PTC->new(
        resource => $self->RESOURCE(),
        name     => $name,
        version  => 'PETC0100',
        data     => BMP2DATA(
            $self->data,
            sp_width  => $sp_width,
            sp_height => $sp_height,
        ),
    );
    return $ptc;
}

sub load {
    my $self  = shift;
    my $ptc   = shift;

    my %opts     = @_;
    my $sp_width = ( $self->RESOURCE() eq 'GRP' )
        ? 64
        : delete $opts{sp_width} || 16;
    my $sp_height = ( $self->RESOURCE() eq 'GRP' )
        ? 64
        : delete $opts{sp_height} || 16;

    my $bmp  = DATA2BMP(
        bytes::substr( $ptc->data, 0x0C ),
        width     => $self->BMP_WIDTH(),
        height    => $self->BMP_HEIGHT(),
        sp_width  => $sp_width,
        sp_height => $sp_height,
    );
    $self->data($bmp);
    return $self;
}

1;
