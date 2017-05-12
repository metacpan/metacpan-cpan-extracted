#!perl -w -T

=head1 NAME

20-taint.t - Regression test for https://rt.cpan.org/Ticket/Display.html?id=95385

=head1 DESCRIPTION

Generating certificates from tainted data (keys, certificate fields and
extensions) is okay, as the resulting X509ish bits will not be used in system
calls etc. This used to not be the case, see RT ticket 95385.

=cut

use strict;
use Test::More "no_plan";

use Test::Taint;
taint_checking_ok();

use Crypt::OpenSSL::CA;
use Crypt::OpenSSL::CA::Test qw(%test_public_keys %test_keys_plaintext);

taint(my $tainted_cakey = $test_keys_plaintext{rsa1024});
ok((my $cakey = Crypt::OpenSSL::CA::PrivateKey->parse($tainted_cakey)),
   "reading tainted private key");

taint(my $tainted_pubkey = $test_public_keys{rsa1024});
ok(my $cert = Crypt::OpenSSL::CA::X509->new(Crypt::OpenSSL::CA::PublicKey->parse_RSA
                                            ($tainted_pubkey)));

# Sign the certificate and re-parse it, typically to ascertain that the right values
# got through.
sub sign {
  my ($unsigned_cert) = @_;
  taint(my $tainted_cipher = "sha256");
  my $cert_as_pem = $cert->sign($cakey, $tainted_cipher);
  taint($cert_as_pem); # For good measure
  return Crypt::OpenSSL::CA::X509->parse($cert_as_pem);
}

is(sign($cert)->get_public_key->to_PEM, $tainted_pubkey,
   "certificate from tainted public key");

taint(my $tainted_serial = "0x1");
$cert->set_serial($tainted_serial);
is(oct(sign($cert)->get_serial), 1, "tainted serial number");

taint(my $tainted_notbefore = "20080204101500Z");
$cert->set_notBefore($tainted_notbefore);
like(sign($cert)->get_notBefore, qr/200802041015/, "tainted notBefore date");

taint(my $tainted_notafter = "22080204101500Z");
$cert->set_notAfter($tainted_notafter);
like(sign($cert)->get_notAfter, qr/220802041015/, ("tainted notAfter date"));

taint(my @tainted_dn = (C => "fr", O => "tainted org", CN => "tainted cert"));
$cert->set_issuer_DN(Crypt::OpenSSL::CA::X509_NAME->new(@tainted_dn));
like(sign($cert)->get_issuer_DN->to_string, qr/tainted org/, "tainted DN");

taint(my $tainted_uri = "http://www.example.com/");
$cert->set_extension(authorityInfoAccess => '@aia_section',
                     aia_section => {'caIssuers;URI' => $tainted_uri});
pass("tainted extension");  # Used to simply crash as of version 0.19
