package Crypt::Perl::X509::Extension::keyUsage;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::X509::Extension::keyUsage

=head1 SYNOPSIS

    my $usage_obj = Crypt::Perl::X509::Extension::keyUsage->new(
        qw(
            digitalSignature
            contentCommitment
            keyEncipherment
            dataEncipherment
            keyAgreement
            keyCertSign
            cRLSign
            encipherOnly
            decipherOnly
        )
    );

=head1 SEE ALSO

L<https://tools.ietf.org/html/rfc5280#section-4.2.1.3>

=cut

use parent qw( Crypt::Perl::X509::Extension );

use Crypt::Perl::ASN1::BitString ();
use Crypt::Perl::X ();

use constant OID => '2.5.29.15';

use constant ASN1 => <<END;
    keyUsage ::= BIT STRING
END

use constant CRITICAL => 1;

#The original bit values are “little-endian”.
#We might as well transmogrify these values for ease of use here.
my @_bits = qw(
    digitalSignature
    contentCommitment
    keyEncipherment
    dataEncipherment
    keyAgreement
    keyCertSign
    cRLSign
    encipherOnly
    decipherOnly
);

sub new {
    my ($class, @usages) = @_;

    #Use the modern name
    $_ =~ s<\AnonRepudiation\z><contentCommitment> for @usages;

    if (!@usages) {
        die Crypt::Perl::X::create('Generic', 'Need usages!');
    }

    return bless \@usages, $class;
}

sub _encode_params {
    my ($self) = @_;

    return Crypt::Perl::ASN1::BitString::encode( \@_bits, [ @$self ] );
}

1;
