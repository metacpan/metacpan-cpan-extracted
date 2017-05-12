package Crypt::Perl::RSA::PKCS1_v1_5;

=encoding utf-8

=head1 NAME

Crypt::Perl::RSA::PKCS1_v1_5 - PKCS1 v1.5 signature padding

=head1 SYNOPSIS

    my $digest = Digest::SHA::sha256('This is my message.');

    my $sig = Crypt::Perl::RSA::PKCS1_v1_5::encode(
        $digest,
        'sha256',   #digest OID; see below
        2048,       #the bit length of the key’s modulus
    );

    #This value should match $digest.
    my $digest_dec = Crypt::Perl::RSA::PKCS1_v1_5::decode(
        $sig,
        'sha256',
    );

=head1 LIST OF DIGEST OIDs

=over 4

=item * sha512

=item * sha384

=item * sha256

=back

The following are considered too weak for good security now;
they’re included for historical interest.

=over 4

=item * sha1

=item * md5

=item * md2

=back

=cut

use strict;
use warnings;

use Crypt::Perl::X ();

#----------------------------------------------------------------------
#RFC 3447, page 42

#These are too weak for modern hardware, but we’ll include them anyway.
use constant DER_header_md2 => "\x30\x20\x30\x0c\x06\x08\x2a\x86\x48\x86\xf7\x0d\x02\x02\x05\x00\x04\x10";
use constant DER_header_md5 => "\x30\x20\x30\x0c\x06\x08\x2a\x86\x48\x86\xf7\x0d\x02\x05\x05\x00\x04\x10";
use constant DER_header_sha1 => "\x30\x21\x30\x09\x06\x05\x2b\x0e\x03\x02\x1a\x05\x00\x04\x14";


#As of December 2016, the following are considered safe for general use.
use constant DER_header_sha256 => "\x30\x31\x30\x0d\x06\x09\x60\x86\x48\x01\x65\x03\x04\x02\x01\x05\x00\x04\x20";
use constant DER_header_sha384 => "\x30\x41\x30\x0d\x06\x09\x60\x86\x48\x01\x65\x03\x04\x02\x02\x05\x00\x04\x30";
use constant DER_header_sha512 => "\x30\x51\x30\x0d\x06\x09\x60\x86\x48\x01\x65\x03\x04\x02\x03\x05\x00\x04\x40";
#----------------------------------------------------------------------

#RFC 3447, section 9.2
sub encode {
    my ($digest, $digest_oid, $emLen) = @_;

    #print "encoding: [$digest_oid]\n";
    my $encoded = _asn1_DigestInfo( $digest, $digest_oid );

    if ( $emLen < length($encoded) + 11 ) {
        die Crypt::Perl::X::create('Generic', sprintf "intended encoded message length (%d bytes) is too short--must be at least %d bytes", $emLen, 11 + length $encoded);
    }

    #NB: The length of $encoded will be a function solely of $digest_oid.

    my $PS = "\x{ff}" x ($emLen - length($encoded) - 3);

    return "\0\1$PS\0$encoded";
}

#Assume that we already validated the length.
sub decode {
    my ($octets, $digest_oid) = @_;

    #printf "$digest_oid - %v02x\n", $octets;

    my $hdr = _get_der_header($digest_oid);

    $octets =~ m<\A \x00 \x01 \xff+ \x00 \Q$hdr\E >x or do {
        my $err = sprintf "Invalid EMSA-PKCS1-v1_5/$digest_oid: %v02x", $octets;
        die Crypt::Perl::X::create('Generic', $err);
    };

    return substr( $octets, $+[0] );
}

sub _get_der_header {
    my ($oid) = @_;

    return __PACKAGE__->can("DER_header_$oid")->();
}

sub _asn1_DigestInfo {
    my ($digest, $oid) = @_;

    return _get_der_header($oid) . $digest;
}

#sub _asn1_DigestInfo {
#    my ($digest, $algorithm_oid) = @_;
#
#    #We shouldn’t need Convert::ASN1 for this.
#    my $asn1 = Crypt::Sign::RSA::Convert_ASN1->new();
#    $asn1->prepare_or_die(
#        q<
#            AlgorithmIdentifier  ::=  SEQUENCE  {
#                algorithm               OBJECT IDENTIFIER,
#                parameters              NULL
#            }
#
#            DigestInfo ::= SEQUENCE {
#                alg AlgorithmIdentifier,
#                digest OCTET STRING
#            }
#        >,
#    );
#
#    my $parser = $asn1->find_or_die('DigestInfo');
#
#    return $parser->encode_or_die(
#        digest => $digest,
#
#        #RFC 3447 says to use “sha256WithRSAEncryption”, but
#        #OpenSSL’s RSA_sign() uses just “sha256”. (??)
#        alg => { algorithm => $algorithm_oid, parameters => 1 },
#    );
#}

1;
