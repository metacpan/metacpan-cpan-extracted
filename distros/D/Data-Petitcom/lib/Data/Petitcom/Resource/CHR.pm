package Data::Petitcom::Resource::CHR;

use strict;
use warnings;

use parent qw{ Data::Petitcom::Resource::GRP };

use constant RESOURCE   => 'CHR';
use constant BMP_WIDTH  => 256;
use constant BMP_HEIGHT => 64;
use constant PTC_NAME   => 'DPTC_CHR';

sub save {
    my $self   = shift;
    my $ptc    = $self->SUPER::save(@_);
    my @pixels = map { sprintf( "%x", $_ % 16 ) }
        unpack 'C*', bytes::substr( $ptc->data, 0x0C );
    my $deflated = pack 'h*', join( '', @pixels );
    $ptc->data($deflated);
    return $ptc;
}

sub load {
    my $self    = shift;
    my $ptc     = shift;
    my @nibbles = split //, unpack( 'h*', bytes::substr( $ptc->data, 0x0C ) );
    my $inflated = pack 'C*', map { hex($_) } @nibbles;
    $ptc->data($inflated);
    $self->SUPER::load( $ptc, @_ );
}

1;
