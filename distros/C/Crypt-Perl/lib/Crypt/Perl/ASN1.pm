package Crypt::Perl::ASN1;

#Wrappers around basic methods to get exceptions thrown on errors.

use strict;
use warnings;

use parent 'Convert::ASN1';

use Crypt::Perl::BigInt ();
use Crypt::Perl::X ();

sub new {
    my ($class, @opts) = @_;

    return $class->SUPER::new(
        encode => { bigint => 'Crypt::Perl::BigInt' },
        decode => { bigint => 'Crypt::Perl::BigInt' },
        @opts,
    );
}

sub prepare {
    my ( $self, $asn1_r ) = ( $_[0], \$_[1] );

    my $ret = $self->SUPER::prepare($$asn1_r);

    if ( !defined $ret ) {
        die Crypt::Perl::X::create('ASN1::Prepare', $$asn1_r, $self->error());
    }

    return $ret;
}

sub find {
    my ( $self, $macro ) = @_;

    return $self->SUPER::find($macro) || do {
        die Crypt::Perl::X::create('ASN1::Find', $macro, $self->error());
    };
}

sub encode {
    my ($self) = shift;

    return $self->SUPER::encode(@_) || do {
        die Crypt::Perl::X::create('ASN1::Encode', \@_, $self->error());
    };
}

sub decode {
    my ($self) = shift;

    return $self->SUPER::decode($_[0]) || do {
        die Crypt::Perl::X::create('ASN1::Decode', $_[0], $self->error());
    };
}

my $_asn1_null;

sub NULL {
    return $_asn1_null ||= Crypt::Perl::ASN1->new()->prepare('n NULL')->encode( { n => 0 } );
}

1;
