#!/usr/bin/env perl
# With the X.509 variant the private key does not have to be given to the
# module: a "signer" function receives the bytes to sign and returns the
# signature. That is how to use keys that cannot leave an HSM or a KMS.
# Here the function just uses CryptX by itself, and logs what it does.
#
#    CERT_FILE=cert.pem KEY_FILE=key.pem ./08-x509-custom-signer.pl
use v5.24;
use warnings;
use experimental 'signatures';
use FindBin '$Bin';
use lib "$Bin/../lib";
use AWS::Signature::V4;
use Crypt::PK::RSA;

my $key = Crypt::PK::RSA->new($ENV{KEY_FILE} // die "KEY_FILE?\n");

my $signer = AWS::Signature::V4->new(
   service => 'rolesanywhere',
   region  => 'eu-west-1',
   x509    => {
      key_type         => 'RSA',
      certificate_file => $ENV{CERT_FILE} // die("CERT_FILE?\n"),
      signer           => sub ($bytes) {
         say STDERR 'signer called on ', length($bytes), ' bytes';
         # RSA: PKCS#1 v1.5 over SHA-256. For ECDSA return the DER signature.
         # Raw bytes: decode first a signature that comes in base64 or hex.
         return $key->sign_message($bytes, 'SHA256', 'v1.5');
      },
   },
);

my $r = $signer->sign(
   method => 'GET',
   url    => 'https://rolesanywhere.eu-west-1.amazonaws.com/profiles',
);
say $r->{authorization};
