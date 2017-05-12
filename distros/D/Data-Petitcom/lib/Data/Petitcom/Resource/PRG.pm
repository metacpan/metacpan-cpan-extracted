package Data::Petitcom::Resource::PRG;

use strict;
use warnings;

use parent qw{ Data::Petitcom::Resource };

use Encode ();
use Unicode::Japanese;
use Data::Petitcom::CharTBL qw{ dump_char load_char };
use Data::Petitcom::PTC;
use bytes ();

use constant RESOUECE        => 'PRG';
use constant PTC_OFFSET_CODE => 0x18;
use constant PTC_NAME        => 'DPTC_PRG';

sub save {
    my $self = shift;
    my %opts = @_;
    my $name     = delete $opts{name} || PTC_NAME;
    my $encoding = delete $opts{encoding};
    my $ptc = $self->_create_ptc($name, $encoding);
    return $ptc;
}

sub load {
    my $self = shift;
    my ( $ptc, %opts ) = @_;
    my $zenkaku  = delete $opts{zenkaku};
    my $encoding = delete $opts{encoding};
    my $code = substr $ptc->data, PTC_OFFSET_CODE;
    $self->data( _decode( $code, $zenkaku, $encoding ) );
    return $self;
}

sub _create_ptc {
    my $self = shift;
    my ($name, $encoding) = @_;
    my $ptc  = Data::Petitcom::PTC->new(
        resource => RESOUECE,
        name     => $name,
    );
    my $code = _encode( $self->data, $encoding );
    my $header_data = pack 'C*', 0x00, 0x00, 0x00, 0x00;
    $header_data .= pack 'C*', 0x00, 0x00, 0x00, 0x00;
    $header_data .= pack 'I', bytes::length( $code );
    $ptc->data( $header_data . $code );
    return $ptc;
}

sub _encode {
    my $code     = shift;
    my $encoding = shift;
    $code = ($encoding)
        ? Encode::find_encoding($encoding)->decode($code)
        : Encode::decode_utf8($code);
    $code = Unicode::Japanese->new($code)->hira2kata->z2h->getu;
    $code =~ s/\r\n/\r/g;
    $code =~ s/\n/\r/g;
    my $encoded = '';
    for my $i ( 0 .. ( length($code) - 1 ) ) {
        my $char = substr( $code, $i, 1 );
        $encoded .= dump_char($char);
    }
    return $encoded;
}

sub _decode {
    my $binary = shift;
    my ( $zenkaku, $encoding ) = @_;
    my $decoded = '';
    for my $i ( 0 .. ( bytes::length($binary) - 1 ) ) {
        my $byte = bytes::substr( $binary, $i, 1 );
        $decoded .= load_char($byte);
    }
    if ($zenkaku) {
        # $decoded = Unicode::Japanese->new($decoded)->h2zKanaK->get;
        # $decoded = Unicode::Japanese->new($decoded)->h2z->get;
        $decoded = Unicode::Japanese->new($decoded)->h2zKanaK->h2z->getu;
    }
    if ($encoding) {
        Encode::from_to( $decoded, 'utf8', $encoding );
    }
    return $decoded;
}

1;
