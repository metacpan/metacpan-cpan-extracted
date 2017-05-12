#!perl -w
# -*- coding: utf-8; -*-

use strict;
use warnings;
use utf8; # This source code contains UTF-8 characters.

=head1 NAME

make-cert-chain.pl - Make an RSA X509 certificate chain using
L<Crypt::OpenSSL::CA>

=head1 DESCRIPTION

This example code walks the reader through using L<Crypt::OpenSSL::CA>
to create X509 certificates.  We demonstrate creating a self-signed
Certification Authority (CA) certificate, and a user certificate
signed by that CA.  Both are printed to standard output as text
strings in L<Crypt::OpenSSL::CA::AlphabetSoup/PEM> format.

=cut

use Crypt::OpenSSL::CA;

=head1 CA SELF-SIGNATURE

=cut

{

=head2 Private Key

Crypt::OpenSSL::CA doesn't create private keys by itself, but the
openssl command-line tool can whip them up presto.  For additional
style points, let's say the CA's key is to be password-protected.

=cut

  our $ca_privkey_as_text = `openssl genrsa -passout pass:secret 1024`;

  my $ca_privkey = Crypt::OpenSSL::CA::PrivateKey->
    parse($ca_privkey_as_text, -password => "secret");

=head2 Certificate

The CA certificate is filled out field after field, starting with the
RSA public key.

=cut

  my $ca_pubkey = $ca_privkey->get_public_key;
  my $ca_cert = Crypt::OpenSSL::CA::X509->new($ca_pubkey);
  my $ca_serial = "0x1";
  $ca_cert->set_serial($ca_serial);
  $ca_cert->set_notBefore("20080204101500Z");
  $ca_cert->set_notAfter("22080204101500Z");

=pod

L<Crypt::OpenSSL::CA::AlphabetSoup/DN>s can be provided literally;
simply be careful to the DN order.

=cut

  my $ca_dn = Crypt::OpenSSL::CA::X509_NAME->new
    (C => "au", OU => "Yoyodyne Inc", CN => "test CA");

  $ca_cert->set_issuer_DN($ca_dn);
  $ca_cert->set_subject_DN($ca_dn);

=pod

Note that we need to set some extensions for that CA certificate in
order for it to be standards-compliant; see
L<Crypt::OpenSSL::CA::Resources> if you are new to that whole shebang.

=cut

  $ca_cert->set_extension("basicConstraints", "CA:TRUE", -critical => 1);

=pod

Okay, we don't really need key identifiers for standards compliance;
they're just here because it's fun to copy them over to the client
certificate later on.

=cut

  my $ca_keyid = $ca_pubkey->get_openssl_keyid;
  $ca_cert->set_extension("subjectKeyIdentifier", $ca_keyid);
  $ca_cert->set_extension("authorityKeyIdentifier" =>
                       {
			keyid => $ca_keyid,
			issuer => $ca_dn,
			serial => $ca_serial
                       });

=pod

Sign it, and the certificate is ready!

=cut

  our $ca_cert_as_text = $ca_cert->sign($ca_privkey, "sha1");
  print $ca_cert_as_text;
}

=head1 USER CERTIFICATE SIGNING REQUEST

We are going to play by the rules, and generate the user's certificate from
public data only; here, using a PKCS#10 Certificate Signing Request
(L<Crypt::OpenSSL::CA::AlphabetSoup/CSR>;
L<Crypt::OpenSSL::CA::AlphabetSoup/SPKAC> is also supported).  Again
L<Crypt::OpenSSL::CA> cannot fabricate PKCS#10's directly, but you could create
one with something like

  openssl req -nodes -batch -newkey rsa:1024 -keyout userkey.pem -out user.p10

Standards-savvy readers know that PKCS#10 requests can contain other
fields than the public key.  However, L<Crypt::OpenSSL::CA> ignores
them entirely.

=cut

{
  my $user_csr_as_text = <<"PKCS10";
-----BEGIN CERTIFICATE REQUEST-----
MIIBhDCB7gIBADBFMQswCQYDVQQGEwJBVTETMBEGA1UECBMKU29tZS1TdGF0ZTEh
MB8GA1UEChMYSW50ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMIGfMA0GCSqGSIb3DQEB
AQUAA4GNADCBiQKBgQCwoel30tZE9ItO0wfQWx3jGFpMLo41iFhFrqlweTJ7iacM
bq58tmpDjEONxhqLkNzm05nb2pylskWzKwLQ9NXvchkzK31HKyp89thiVL7ILClV
YRYMz4QLeB75W+xl6q2pcClQ3NrN7CrR9czvmVFOXNWKWxyQXYi2Ad0qVvNF+wID
AQABoAAwDQYJKoZIhvcNAQEFBQADgYEAFL1txli+LGSS4V1sVSRdMh054QVk9TKY
50HTKYR44aCax3fDcnp4H7jR5QEHX0TeHCC5cr8cDDWLEYmCb0UBXr70czrap3n2
Du3EgKJUHSURsNbkSHSBKupLrw9Ygmipl4vvHRAX59Bqbz4LGEhALnx0eiwK1TtQ
mk7h7g7cYc8=
-----END CERTIFICATE REQUEST-----
PKCS10

  my $user_pubkey = Crypt::OpenSSL::CA::PublicKey->
    validate_PKCS10($user_csr_as_text);

=head1 USER CERTIFICATE CREATION

In a real PKI this would probably not take place in the same process
as the L</CA SELF-SIGNATURE> step.  So let's pretend that we are
reloading from serialized state (ie PEM strings) instead of re-using
the objects created above.  (To keep ourselves honest, we used curly
braces in the Perl script to segregate both signing operations into
different lexical scopes.)

=cut

  my $ca_cert = Crypt::OpenSSL::CA::X509->
    parse(our $ca_cert_as_text);
  my $ca_privkey = Crypt::OpenSSL::CA::PrivateKey->
    parse(our $ca_privkey_as_text, -password => "secret");

=pod

In order for the user certificate and the CA certificate to chain
properly, certain fields in the latter must match those in the former.
L<Crypt::OpenSSL::CA> supports enough of X509 parsing that we are able
to extract those from an existing PEM certificate.

=cut

  my $ca_dn = $ca_cert->get_subject_DN();
  my $ca_keyid = $ca_cert->get_subject_keyid;

=head2 Certificate Fields and Extensions

This time, let'use a Christmas-treeish set of extensions to
demonstrate the possibilities of the API.  For the X509-savvy, here is
some babble about what L<Crypt::OpenSSL::CA> can do: the X509 version
is always X509v3.  Long serial numbers are supported.  DNs enjoy full
UTF-8 support.  The validity period (notBefore and notAfter) can be of
arbitrary size, and transition from utcTime to generalizedTime is
handled properly.  SubjectAltNames are fully supported regardless of
type and multiplicity; ditto for certificate policies.  The signature
algorithm is RSA and the hash can be set to any of OpenSSL's supported
hashes.  OpenSSL's algorithm for RSA key fingerprints (also known as
X509 KeyIDs) is available (but not mandatory) for the subject and
authority key identifiers.

=cut

  my $user_cert = Crypt::OpenSSL::CA::X509->new($user_pubkey);

  my $user_dn = Crypt::OpenSSL::CA::X509_NAME->new_utf8
    (C => "fr", O => "zoinxé",
     OU => "☮☺⌨", # Peace, joy, coding :-)
     CN => "test user cert");

  $user_cert->set_issuer_DN($ca_dn);
  $user_cert->set_subject_DN($user_dn);

  $user_cert->set_serial("0x1234567890abcdef1234567890ABCDEF");

  $user_cert->set_notBefore("20080204114600Z");
  $user_cert->set_notAfter("21060108000000Z");
  $user_cert->set_extension("basicConstraints", "CA:FALSE",
                         -critical => 1);

  $user_cert->set_extension("authorityKeyIdentifier",
                       { keyid => $ca_keyid },
                       -critical => 0); # As per RFC3280 section 4.2.1.1
  $user_cert->set_extension( subjectKeyIdentifier =>
                        "00:DE:AD:BE:EF"); # Hey, why not?

  $user_cert->set_extension(certificatePolicies =>
                       'ia5org,1.2.3.4,1.5.6.7.8,@polsect',
                       -critical => 0,
                       polsect => {
                            policyIdentifier => '1.3.5.8',
                            "CPS.1"        => 'http://my.host.name/',
                            "CPS.2"        => 'http://my.your.name/',
                            "userNotice.1" => '@notice',
                         },
                         notice => {
                            explicitText  => "Explicit Text Here",
                            organization  => "Organisation Name",
                            noticeNumbers => '1,2,3,4',
                         });

  $user_cert->set_extension
    (subjectAltName => 'email:johndoe@example.com,email:johndoe@example.net');

  my $fancy_digest_alg = "ripemd160";  # I'd use "sha256" myself, but
  # some old builds of OpenSSL don't have it.
  warn "And here is a certificate using $fancy_digest_alg as the digest!\n";

  our $user_cert_as_text = $user_cert->sign($ca_privkey, $fancy_digest_alg);
  print $user_cert_as_text;
}

exit 0;
