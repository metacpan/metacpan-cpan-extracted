use strict;
use warnings;
use Test::More;
use MIME::Base64    qw/decode_base64/;
use File::Temp      qw/ tempfile /;

use Crypt::OpenSSL::RSA;
use Crypt::OpenSSL::Bignum;

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}
my ($rsa_fh, $rsa_file) = tempfile(UNLINK => 1);

# Create a new RSA key
`openssl genrsa -out $rsa_file 2048 > /dev/null 2>&1`;

# Get the output as text that includes the private key PEM
my $priv_output = `openssl rsa -inform PEM -in $rsa_file -text 2>&1`;

# X.509 SubjectPublicKeyInfo format (BEGIN PUBLIC KEY)
my $pub_x509_output = `openssl rsa -inform PEM -in $rsa_file -pubout -text 2>&1`;

# PKCS#1 RSAPublicKey format (BEGIN RSA PUBLIC KEY)
my $pub_pkcs1_output = `openssl rsa -inform PEM -in $rsa_file -RSAPublicKey_out -text 2>&1`;

# Basic grab multi-line data between
# two tags from openssl -text output
sub get_parameter {
    my $text    = shift;
    my $start   = shift;
    my $end     = shift;

    # Fieldname may end in ':'
    $text =~ /$start:*\s*(.*?)\s*$end:*/s;
    my $parameter = $1;
    return undef unless defined $parameter;
    # Remove ':' and white space including newlines
    $parameter =~ s/[:\s]//g;

    # The exponent data we want is the hex data
    # with no 0x prefix
    if($parameter =~ /\((.*?)\)/ ) {
        $parameter = $1;
        $parameter =~ s/0x//g;
    }
    return $parameter;
}

# Extract the base64 PEM body between header/footer lines
sub extract_pem_body {
    my ($text, $header_re, $footer_re) = @_;
    if ($text =~ /($header_re)\s*(.*?)\s*($footer_re)/s) {
        my $body = $2;
        $body =~ s/\s//g;
        return $body;
    }
    return undef;
}

# Compare a bignum to hex data
sub compare_bignum_to_hex {
    my $bn1 = shift;
    my $hex = shift;

    my $bn2 = Crypt::OpenSSL::Bignum->new_from_hex($hex);
    isa_ok($bn2, 'Crypt::OpenSSL::Bignum');
    return $bn2->cmp($bn1);
}

####################
# Check private key
####################
diag("Check private key");
# Extract the values from the openssl private key output
my $priv_n = get_parameter($priv_output, 'modulus', 'publicExponent');
my $priv_e = get_parameter($priv_output, 'publicExponent', 'privateExponent');
my $priv_d = get_parameter($priv_output, 'privateExponent', 'prime1');
my $priv_p = get_parameter($priv_output, 'prime1', 'prime2');
my $priv_q = get_parameter($priv_output, 'prime2', 'exponent1');
my $priv_dmp1 = get_parameter($priv_output, 'exponent1', 'exponent2');
my $priv_dmq1 = get_parameter($priv_output, 'exponent2', 'coefficient');
my $priv_iqmp = get_parameter($priv_output, 'coefficient', '-----BEGIN .*PRIVATE KEY-----');
my $priv_pem = extract_pem_body($priv_output,
    '-----BEGIN .*PRIVATE KEY-----', '-----END .*PRIVATE KEY-----');

# Load the private key from the DER (base64 decoded PEM)
my $rsa = Crypt::OpenSSL::RSA->new_private_key(decode_base64($priv_pem));

# Get the private key parameters
my ($n, $e, $d, $p, $q, $dmp1, $dmq1, $iqmp) = $rsa->get_key_parameters();

# Check each private key parameter to the expected values
ok(compare_bignum_to_hex($n, $priv_n) == 0, "Imported DER n parameter matches expected");
ok(compare_bignum_to_hex($e, $priv_e) == 0, "Imported DER e parameter matches expected");
ok(compare_bignum_to_hex($d, $priv_d) == 0, "Imported DER d parameter matches expected");
ok(compare_bignum_to_hex($p, $priv_p) == 0, "Imported DER p parameter matches expected");
ok(compare_bignum_to_hex($q, $priv_q) == 0, "Imported DER q parameter matches expected");
ok(compare_bignum_to_hex($dmp1, $priv_dmp1) == 0, "Imported DER dmp1 parameter matches expected");
ok(compare_bignum_to_hex($dmq1, $priv_dmq1) == 0, "Imported DER dmq1 parameter matches expected");
ok(compare_bignum_to_hex($iqmp, $priv_iqmp) == 0, "Imported DER iqmp parameter matches expected");

###################################
# Check X.509 SubjectPublicKeyInfo
###################################
diag("Check X.509 public key (from -pubout)");
# Extract PEM body — -pubout produces X.509 SubjectPublicKeyInfo (BEGIN PUBLIC KEY)
my $pub_x509_pem = extract_pem_body($pub_x509_output,
    '-----BEGIN PUBLIC KEY-----', '-----END PUBLIC KEY-----');

# Load the public key from the DER (base64 decoded PEM)
my $pub_x509_rsa = Crypt::OpenSSL::RSA->new_public_key(decode_base64($pub_x509_pem));

# Get the key parameters
my ($px_n, $px_e, $px_d, $px_p, $px_q, $px_dmp1, $px_dmq1, $px_iqmp) = $pub_x509_rsa->get_key_parameters();

# n and e should match the private key's values (same key)
ok(compare_bignum_to_hex($px_n, $priv_n) == 0, "X.509 public DER n matches private key n");
ok(compare_bignum_to_hex($px_e, $priv_e) == 0, "X.509 public DER e matches private key e");
ok(!$px_d, "X.509 public DER d parameter undef as expected");
ok(!$px_p, "X.509 public DER p parameter undef as expected");
ok(!$px_q, "X.509 public DER q parameter undef as expected");
ok(!$px_dmp1, "X.509 public DER dmp1 parameter undef as expected");
ok(!$px_dmq1, "X.509 public DER dmq1 parameter undef as expected");
ok(!$px_iqmp, "X.509 public DER iqmp parameter undef as expected");

#############################
# Check PKCS#1 RSAPublicKey
#############################
diag("Check PKCS#1 public key (from -RSAPublicKey_out)");
# Extract PEM body — -RSAPublicKey_out produces PKCS#1 (BEGIN RSA PUBLIC KEY)
my $pub_pkcs1_pem = extract_pem_body($pub_pkcs1_output,
    '-----BEGIN RSA PUBLIC KEY-----', '-----END RSA PUBLIC KEY-----');

SKIP: {
    skip "openssl does not support -RSAPublicKey_out", 8
        unless defined $pub_pkcs1_pem && length($pub_pkcs1_pem) > 0;

    # Load the public key from the DER (base64 decoded PEM)
    my $pub_pkcs1_rsa = Crypt::OpenSSL::RSA->new_public_key(decode_base64($pub_pkcs1_pem));

    # Get the key parameters
    my ($pn, $pe, $pd, $pp, $pq, $pdmp1, $pdmq1, $piqmp) = $pub_pkcs1_rsa->get_key_parameters();

    # n and e should match the private key's values (same key)
    ok(compare_bignum_to_hex($pn, $priv_n) == 0, "PKCS#1 public DER n matches private key n");
    ok(compare_bignum_to_hex($pe, $priv_e) == 0, "PKCS#1 public DER e matches private key e");
    ok(!$pd, "PKCS#1 public DER d parameter undef as expected");
    ok(!$pp, "PKCS#1 public DER p parameter undef as expected");
    ok(!$pq, "PKCS#1 public DER q parameter undef as expected");
    ok(!$pdmp1, "PKCS#1 public DER dmp1 parameter undef as expected");
    ok(!$pdmq1, "PKCS#1 public DER dmq1 parameter undef as expected");
    ok(!$piqmp, "PKCS#1 public DER iqmp parameter undef as expected");
}

done_testing();
