#!perl -w

use strict;
use warnings;

=head1 NAME

make-crls.pl - Example code to make RFC3280-compliant CRLv2s with
L<Crypt::OpenSSL::CA>

=cut

use Crypt::OpenSSL::CA;

=head1 DESCRIPTION

The test private keys and certificates are assumed to be generated
already.  See C<make-cert-chain.pl> in the same directory to see how
to do that.

=cut

my $ca_certificate = Crypt::OpenSSL::CA::X509->parse
   (ca_certificate_as_text());
my $ca_privatekey  = Crypt::OpenSSL::CA::PrivateKey->parse
    (ca_privkey_as_text());

=head2 Issuer coordinates

The issuer DN and key identifiers are taken directly from the CA
certificate.

=cut

our $issuer_dn = $ca_certificate->get_subject_DN;
our $keyid     = $ca_certificate->get_subject_keyid;

=head2 CRL Number

Long ASN1 integers are supported.

=cut

our $crlnumber = "0x" . ("deadbeef" x 5);

=head1 REGULAR CRL

First things first.

=head2 Global CRL settings

CRL dates are supported using the dual ASN.1 date format in
conformance with RFC3280 sections 5.1.2.4 and 5.1.2.5.

RFC3280 section 5.1.2.1 now makes v2 for CRLs mandatory; not
coincidentally, this is the default in L<Crypt::OpenSSL::CA>.  The
C<authorityKeyIdentifier> and C<crlNumber> extensions are also
mandatory.  C<authorityKeyIdentifier> MUST NOT be critical as per
section 4.2.1.1, while C<crlNumber> MUST be as per 5.1.2.1.

=cut

{
  my $crl = new Crypt::OpenSSL::CA::X509_CRL;
  $crl->set_issuer_DN($issuer_dn);
  $crl->set_lastUpdate("20070101000000Z");
  $crl->set_nextUpdate("20570101000000Z");

  $crl->set_extension("authorityKeyIdentifier", { keyid => $keyid });
  $crl->set_extension("crlNumber", $crlnumber, -critical => 1);

=pod

Just for fun, we add a C<freshestCRL> extension as per RFC3280 section
5.2.6; the corresponding delta CRL is issued below, see L</DELTA CRL>.

=cut

  $crl->set_extension("freshestCRL",
                      "URI:http://www.example.com/deltacrl.crl",
                      -critical => 0);

=head2 Revoked Certificates List

In order of appearance: a CRLv1-like unadorned entry, an entry with
C<unspecified> revocation reason, an entry for a certificate that was
put on hold (that is removed by the delta-CRL, see below), and an
entry for a certificate whose key was compromised (with a
compromiseTime set).  Notice that the CRL entries are in no particular
order.

=cut

  $crl->add_entry("0x10", "20070212100000Z");
  $crl->add_entry("0x11", "20070212100100Z", -reason => "unspecified");
  $crl->add_entry("0x42", "20070212090100Z",
                  -hold_instruction => "holdInstructionPickupToken");
  $crl->add_entry("0x12", "20070212100200Z", -reason => "keyCompromise",
                  -compromise_time => "20070210000000Z");

=head2 All done

Now we just have to sign the CRL.

=cut

  my $crlpem = $crl->sign($ca_privatekey, "sha1");
  print $crlpem;
}

=head1 DELTA CRL

Because we can.

=cut

{
  my $deltacrl = new Crypt::OpenSSL::CA::X509_CRL;
  $deltacrl->set_issuer_DN($issuer_dn);
  $deltacrl->set_lastUpdate("20070212150000Z");
  $deltacrl->set_nextUpdate("20570101000000Z");
  $deltacrl->set_extension("authorityKeyIdentifier", { keyid => $keyid });

=pod

(Just make sure to update the CRL number as per RFC3280, section 5.2.3)

=cut
  my $deltacrlnumber = $crlnumber; $deltacrlnumber =~ s/beef$/bef0/;
  $deltacrl->set_extension("crlNumber", $deltacrlnumber, -critical => 1);
  $deltacrl->set_extension("deltaCRLIndicator", $crlnumber,
                      -critical => 1 # as per RFC3280 section 5.2.4
                     );

=head2 Revoked Certificates List

We add a revoked certificate to the CRL, and remove the hold
instruction from certificate 0x42.

=cut

  $deltacrl->add_entry("0x42", "20070212150900Z", -reason => "removeFromCRL");
  $deltacrl->add_entry("0xdeadbeefdeaff00f", "20070212151000Z");

=head2 All done

Now we just have to sign the CRL.

=cut

  my $deltacrlpem = $deltacrl->sign($ca_privatekey, "sha1");
  print $deltacrlpem;
}

exit 0;

=head1 TEST DATA

=cut

sub ca_certificate_as_text { <<'PEM' }
-----BEGIN CERTIFICATE-----
MIICsDCCAhmgAwIBAgIJANdqtXzdPS/1MA0GCSqGSIb3DQEBBQUAMEUxCzAJBgNV
BAYTAkFVMRMwEQYDVQQIEwpTb21lLVN0YXRlMSEwHwYDVQQKExhJbnRlcm5ldCBX
aWRnaXRzIFB0eSBMdGQwHhcNMDcwMTMxMTcwNjU5WhcNMzcwMTMxMTcwNjU5WjBF
MQswCQYDVQQGEwJBVTETMBEGA1UECBMKU29tZS1TdGF0ZTEhMB8GA1UEChMYSW50
ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKB
gQDfGYmlOYbpGkBD/agTUnixLcdh6H1XM13w17RbzaoA7byZD6L+Dn8MZd69PuXc
ZAQEUG4Oe6QyAcafsvDb7SHjyJHLoPTOsAZ0ex/0zIJVpw+XyppA8fZx6bnuHKUa
bqfj83OLk/ACfQSBX7bcL7Y8hwYcZJcqyjMzt9BT7oCldwIDAQABo4GnMIGkMB0G
A1UdDgQWBBTu+qGX79xcvFE8pG5zx2FcqAuV5TB1BgNVHSMEbjBsgBTu+qGX79xc
vFE8pG5zx2FcqAuV5aFJpEcwRTELMAkGA1UEBhMCQVUxEzARBgNVBAgTClNvbWUt
U3RhdGUxITAfBgNVBAoTGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZIIJANdqtXzd
PS/1MAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQEFBQADgYEACQ+4e3MSlcqkhzgZ
rTXpsO/WpBT7aaM7AaecY54hB9uF9PmGC1q3axwZ2b/+Gh5ehQPyAwKevyjNz1y4
yP4YeUHO6FIHd0RyGEnM3cqcoqg8TewXlUwOkHphCrZ5eFbxxEarVz1wwkZqd5z0
3IInE3EJ7D8rxfbC1c1fdeh8akI=
-----END CERTIFICATE-----
PEM

sub ca_privkey_as_text { <<'PEM' }
-----BEGIN RSA PRIVATE KEY-----
MIICXgIBAAKBgQDfGYmlOYbpGkBD/agTUnixLcdh6H1XM13w17RbzaoA7byZD6L+
Dn8MZd69PuXcZAQEUG4Oe6QyAcafsvDb7SHjyJHLoPTOsAZ0ex/0zIJVpw+XyppA
8fZx6bnuHKUabqfj83OLk/ACfQSBX7bcL7Y8hwYcZJcqyjMzt9BT7oCldwIDAQAB
AoGBANWLUi8uUy4IDH+H6jskc5XUJcZXjLHM3xxKu74rq4/b/uvbBb58DavGTl+C
Nu6vZRDkE5QVUOL0xDPUSauY3RerFnMPdTZZ43WAKYbrrNqA0/xEpEAWv4CxXAMI
f3Bf2ypBdFzE268HiaQxv//61ZtIjb7NDu8j6gcRLLVjU0RhAkEA9X0TZScqGLFR
84GsSltkoSzx2Q+6d81yjzC27CtQgwEUCFhvFG69jAUzJASogac0hmkGa1lVzylO
5D2wgL24PwJBAOinC/ey4XE3isah86Kpgfj8yVj5vtLEodBkUmhNOIrgiHt6+QE+
5YwreJikzRB2Bs9idglg+f/0nqlLdKLWBMkCQQDZNxvjRD0+biAKa/IMNUQcTU2N
+BnRictVIhCpdkYeNOUJ4V4gYUB81dkDhM+pMU8Lo4CXmguQa4ev81nrAHQ3AkBh
ffbW4p/0OKkv2Zfl9xBfDVc2sNlVK07/q7qYuJtUHwkybXLBIeFBXsoXdR/1oO/z
obgC8B9zMcf2+4ax4et5AkEAsNLkUpS5EmsdlyuUnHxg5jU30o8XSUznmzR7OX/H
hP36rGgrE4mclD0LgazRRMjmWFzT6/RtiQb5OnfFxXaDTQ==
-----END RSA PRIVATE KEY-----
PEM

