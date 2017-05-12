package Convert::SSH2::Format::PKCS8;

our $VERSION = '0.01';

use Moo;
extends 'Convert::SSH2::Format::Base';

use Carp qw(confess);
use MIME::Base64 qw(encode_base64);
use Convert::ASN1;

=head1 NAME

Convert::SSH2::Format::PKCS8 - Format SSH key data as PKCS8

=head1 PURPOSE

This module formats SSH2 RSA public keys as PKCS8 strings.

These look like
 
  -----BEGIN PUBLIC KEY-----
  ... Base64 data ...
  -----END PUBLIC KEY-----

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

    SEQUENCE {
        SEQUENCE {
            OBJECT IDENTIFIER rsaEncryption (1 2 840 113549 1 1 1),
            NULL
        }
        BIT STRING {
            RSAPublicKey ::= SEQUENCE {
                modulus           INTEGER,  -- n
                publicExponent    INTEGER   -- e
            }
        }
    }

=back

=cut

has 'asn_template' => (
    is => 'ro',
    default => sub {
return <<_EOT;
key SEQUENCE {
    algo SEQUENCE {
        id OBJECT IDENTIFIER,
        n NULL
    }
    bs BIT STRING
}
_EOT
    },
);

=head1 METHOD

=over

=item generate()

Returns a PKCS8 formatted string, given C<n> and C<e>.

=back

=cut

sub generate {
    my $self = shift;

    $self->asn->prepare(q|
rsa SEQUENCE {
    mod INTEGER,
    exp INTEGER
}
|) or die;

    my $rsa_asn = $self->asn->encode(
        rsa => {
            mod => $self->n,
            exp => $self->e,
        }
    ) or die;

    $self->asn->prepare($self->asn_template) or die;

    my $pdu = $self->asn->encode(
            key => { 
                algo => { 
                    id => '1.2.840.113549.1.1.1',
                    n => '',
                },
                bs => $rsa_asn, 
            }
    ) or die;

    my $b64 = encode_base64($pdu, "");

    my $out = "-----BEGIN PUBLIC KEY-----\n";
      $out .= $self->format_lines($b64);
      $out .= "-----END PUBLIC KEY-----\n";

    return $out;
}

=head1 SEE ALSO

L<Convert::SSH2>

=cut

1;
