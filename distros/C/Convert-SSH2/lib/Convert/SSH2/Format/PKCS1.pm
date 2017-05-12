package Convert::SSH2::Format::PKCS1;

our $VERSION = '0.01';

use Moo;
extends 'Convert::SSH2::Format::Base';

use Carp qw(confess);
use MIME::Base64 qw(encode_base64);
use Convert::ASN1;

=head1 NAME

Convert::SSH2::Format::PKCS1 - Format SSH key data as PKCS1

=head1 PURPOSE

This module formats SSH2 RSA public keys as PKCS1 strings.

Generally, you shouldn't instantiate this class on its own.  It will be called by L<Convert::SSH2>
when needed.

=head1 ATTRIBUTES

=over

=item asn

Holds an ASN converter. Defaults to L<Convert::ASN1>.

=back

=cut

has 'asn' => (
    is => 'ro',
    default => sub { Convert::ASN1->new(); },
);

=over

=item asn_template

The ASN encoding template.

Defaults to:

    RSAPublicKey ::= SEQUENCE {
        modulus           INTEGER,  -- n
        publicExponent    INTEGER   -- e
    }

=back

=cut

has 'asn_template' => (
    is => 'ro',
    default => sub {
return <<_EOT;
RSAPublicKey ::= SEQUENCE {
    modulus           INTEGER,  -- n
    publicExponent    INTEGER   -- e
}
_EOT
    },
);


=head1 METHOD

=over

=item generate()

Returns a PKCS#1 formatted string, given C<n> and C<e>.

=back

=cut

sub generate {
    my $self = shift;

    $self->asn->prepare($self->asn_template) or confess;

    my $pdu = $self->asn->encode(
                   modulus => $self->n,
            publicExponent => $self->e,
    ) or confess;

    my $b64 = encode_base64($pdu, "");

    my $out = "-----BEGIN RSA PUBLIC KEY-----\n";
      $out .= $self->format_lines($b64);
      $out .= "-----END RSA PUBLIC KEY-----\n";

    return $out;
}

=head1 SEE ALSO

L<Convert::SSH2>

=cut

1;
