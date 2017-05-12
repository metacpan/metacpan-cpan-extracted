package Crypt::Perl::ECDSA::EC::Curve;

=encoding utf-8

=head1 NAME

Crypt::Perl::ECDSA::EC::Curve

=head1 DISCUSSION

This interface is undocumented for now.

=cut

use strict;
use warnings;

use Crypt::Perl::ECDSA::EC::FieldElement ();
use Crypt::Perl::ECDSA::EC::Point ();
use Crypt::Perl::X ();

#All bigints
sub new {
    my ( $class, $q, $a, $b ) = @_;

    die Crypt::Perl::X::create('Generic', 'Need q, a, and b!') if grep { !defined } $q, $a, $b;

    my $self = {
        q => $q,
        a => $a,
        b => $b,
        infinity => Crypt::Perl::ECDSA::EC::Point->new_infinity(),
    };

    return bless $self, $class;
}

sub keylen {
    my ($self) = @_;

    return $self->{'q'}->bit_length();
}

sub get_infinity {
    my ($self) = @_;
    return $self->{'infinity'};
}

#Returns ECFieldElement
sub decode_point {
    my ($self, $x, $y) = @_;

    #if ( $self->as_hex() =~ m<\A0x0[467]> ) {
    #    die 'Only uncompressed generators!';
    #}

    return Crypt::Perl::ECDSA::EC::Point->new( $self, $self->from_bigint( $x ), $self->from_bigint( $y ) );
}

#$x is a bigint
sub from_bigint {
    my ($self, $x ) = @_;

    return Crypt::Perl::ECDSA::EC::FieldElement->new( $self->{'q'}, $x );
}

1;
