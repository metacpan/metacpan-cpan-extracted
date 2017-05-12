package Crypt::Perl::ASN1::Encodee;

use strict;
use warnings;

use Crypt::Perl::ASN1 ();
use Crypt::Perl::X ();

sub asn1_macro {
    my ($self_or_class) = @_;

    my $class = ref($self_or_class) || $self_or_class;

    $class =~ m<.+::(.+)> or die Crypt::Perl::X::create('Generic', "Invalid class: “$class”");

    return $1;
}

sub encode {
    my ($self) = @_;

    my $asn1 = Crypt::Perl::ASN1->new();
    $asn1 = $asn1->prepare( $self->ASN1() )->find( $self->asn1_macro() );

    return $asn1->encode( $self->_encode_params() );
}

1;
