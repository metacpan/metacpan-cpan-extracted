#!/usr/bin/perl
use strict;
use warnings;
use MIME::Base64 qw(decode_base64);
use Convert::ASN1;

# ── DER encoding helpers ────────────────────────────────────────────────────────
sub _der_length {
    my ($len) = @_;
    if ($len < 128) {
        return chr($len);
    } else {
        my @bytes;
        while ($len > 0) {
            unshift @bytes, chr($len & 0xFF);
            $len >>= 8;
        }
        return chr(0x80 | scalar(@bytes)) . join('', @bytes);
    }
}

sub _encode_sequence_of {
    my ($items) = @_;
    my $content = join('', @$items);
    my $len_der = _der_length(length($content));
    return "\x30" . $len_der . $content;  # 0x30 = SEQUENCE tag
}

# ── OIDs ────────────────────────────────────────────────────────────────────
my $OID_PKCS7_DATA   = '1.2.840.113549.1.7.1';
my $OID_CERT_BAG     = '1.2.840.113549.1.12.10.1.3';
my $OID_X509_CERT    = '1.2.840.113549.1.9.22.1';
my $OID_SHA256       = '2.16.840.1.101.3.4.2.1';
my $OID_ZERO_OCTET   = '1.2.3.100';
my $OID_ZERO_BIT     = '1.2.3.101';

# ── Load certificate DER from PEM ───────────────────────────────────────────
my $cert_file = 'certs/test-cert.pem';
open my $fh, '<', $cert_file or die "Cannot open $cert_file: $!";
my $cert_pem = do { local $/; <$fh> };
close $fh;
(my $cert_b64 = $cert_pem) =~ s/-----[^-]+-----//g;
$cert_b64 =~ s/\s+//g;
my $cert_der = decode_base64($cert_b64);

# ── ASN.1 schema ─────────────────────────────────────────────────────────────
my $asn = Convert::ASN1->new;
$asn->prepare(q{
    PFX ::= SEQUENCE {
        version   INTEGER,
        authSafe  ContentInfo,
        macData   MacData OPTIONAL
    }
    ContentInfo ::= SEQUENCE {
        contentType OBJECT IDENTIFIER,
        content     [0] EXPLICIT ANY OPTIONAL
    }
    AuthSafeContents ::= SEQUENCE OF ContentInfo
    MacData ::= SEQUENCE {
        mac        DigestInfo,
        macSalt    OCTET STRING,
        iterations INTEGER OPTIONAL
    }
    DigestInfo ::= SEQUENCE {
        digestAlgorithm AlgorithmIdentifier,
        digest          OCTET STRING
    }
    AlgorithmIdentifier ::= SEQUENCE {
        algorithm  OBJECT IDENTIFIER,
        parameters ANY OPTIONAL
    }
    SafeContents ::= SEQUENCE OF SafeBag
    SafeBag ::= SEQUENCE {
        bagId       OBJECT IDENTIFIER,
        bagValue    [0] EXPLICIT ANY,
        bagAttributes SET OF Attribute OPTIONAL
    }
    Attribute ::= SEQUENCE {
        attrType   OBJECT IDENTIFIER,
        attrValues SET OF ANY
    }
    CertBag ::= SEQUENCE {
        certId    OBJECT IDENTIFIER,
        certValue [0] EXPLICIT ANY
    }
}) or die $asn->error;

# ── Encode helpers ───────────────────────────────────────────────────────────
my $certbag_asn      = $asn->find('CertBag')           or die $asn->error;
my $sc_asn           = $asn->find('SafeContents')       or die $asn->error;
my $ci_asn           = $asn->find('ContentInfo')        or die $asn->error;
my $auth_safe_ci_asn = $asn->find('AuthSafeContents')   or die $asn->error;
my $pfx_asn          = $asn->find('PFX')                or die $asn->error;

# ── Encode OCTET STRING helper ────────────────────────────────────────────────
my $octet_asn;
{
    my $a = Convert::ASN1->new;
    $a->prepare('wrap ::= OCTET STRING') or die $a->error;
    $octet_asn = $a->find('wrap') or die "Cannot find 'wrap'";
}

# ── Build certificate bag value (CertBag) ───────────────────────────────────
# certValue must be an OCTET STRING wrapping the DER-encoded certificate,
# not raw DER bytes — PKCS12_unpack_p7data() expects the OCTET STRING tag.
my $cert_octet = $octet_asn->encode($cert_der)
    or die "Cannot encode cert OCTET STRING: " . $octet_asn->error;

my $certbag_der = $certbag_asn->encode({
    certId    => $OID_X509_CERT,
    certValue => $cert_octet,
}) or die $certbag_asn->error;

# ── Build SafeContents ────────────────────────────────────────────────────────
# SafeContents is a SEQUENCE OF SafeBag, each SafeBag having zero-length
# bag attributes to exercise the null-termination bug fix.
my $sc_der = $sc_asn->encode([ {
    bagId         => $OID_CERT_BAG,
    bagValue      => $certbag_der,
    bagAttributes => [
        { attrType => $OID_ZERO_OCTET, attrValues => [ "\x04\x00" ] },
        { attrType => $OID_ZERO_BIT,   attrValues => [ "\x03\x01\x00" ] },
    ],
} ]) or die $sc_asn->error;

# ── Wrap SafeContents per PKCS12 structure ────────────────────────────────────
# The authSafe content is: OCTET STRING { SEQUENCE OF ContentInfo }
# Each inner ContentInfo wraps the SafeContents as another PKCS7 Data:
#   ContentInfo { contentType = pkcs7-data, content = [0] OCTET STRING { SafeContents } }
# This SEQUENCE OF ContentInfo is then wrapped in an outer OCTET STRING.

# Step 1: wrap SafeContents in an OCTET STRING (inner PKCS7 Data payload)
my $octet_sc = $octet_asn->encode($sc_der)
    or die "Cannot encode SafeContents OCTET STRING: " . $octet_asn->error;

# Step 2: build a ContentInfo wrapping the SafeContents
my $inner_ci_der = $ci_asn->encode({
    contentType => $OID_PKCS7_DATA,
    content     => $octet_sc,
}) or die $ci_asn->error;

# Step 3: build the SEQUENCE OF ContentInfo (AuthSafeContents)
# Use the pre-encoded ContentInfo and manually build the SEQUENCE OF to avoid
# potential Convert::ASN1 nesting issues.
my $auth_safe_seq_der = _encode_sequence_of([$inner_ci_der])
    or die "Cannot encode AuthSafeContents";

# Step 4: wrap that SEQUENCE in an OCTET STRING for the outer PFX ContentInfo
my $octet_auth_safe = $octet_asn->encode($auth_safe_seq_der)
    or die "Cannot encode authSafe OCTET STRING: " . $octet_asn->error;

# ── Assemble PFX ─────────────────────────────────────────────────────────────
# MacData must be present so pkcs12->mac is not NULL on OpenSSL <= 1.1.0.
# info_as_hash() does not call PKCS12_verify_mac() so correctness is not needed.
# Use SHA-256 for the MAC algorithm (OpenSSL 3.x does not load hmacWithSHA1
# without the legacy provider).
my $pfx_der = $pfx_asn->encode({
    version  => 3,
    authSafe => {
        contentType => $OID_PKCS7_DATA,
        content     => $octet_auth_safe,
    },
    macData => {
        mac => {
            digestAlgorithm => { algorithm => $OID_SHA256 },
            digest          => "\x00" x 32,   # 32 dummy bytes (SHA-256 size)
        },
        macSalt    => "\x00" x 8,
        iterations => 2048,
    },
}) or die $pfx_asn->error;

# ── Write output ─────────────────────────────────────────────────────────────
my $out_file = 'certs/zero-length-attrs.p12';
open my $out, '>', $out_file or die "Cannot write $out_file: $!";
binmode $out;
print $out $pfx_der;
close $out;

print "Written: $out_file\n";
