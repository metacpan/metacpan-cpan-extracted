#!perl -w

use strict;
use warnings;

=head1 NAME

example-make-cert-chain.t - Checks that L<examples/make-cert-chain.t>
works and produces an RFC3280-valid certificate chain.

=cut

use Test::More "no_plan";

use Crypt::OpenSSL::CA::Test qw(run_perl_script_ok run_thru_openssl
                                dumpasn1_available run_dumpasn1
                                certificate_chain_ok);

use File::Spec::Functions qw(catfile);

my $stdout = "";
run_perl_script_ok(catfile("examples", "make-cert-chain.pl"),
                   \$stdout, "make-cert-chain.pl runs without errors");

my @certs = $stdout =~ m/(-+BEGIN\ CERTIFICATE-+$
                             .*?
                             ^-+END\ CERTIFICATE-+$)/gmsx;
is(scalar(@certs), 2, "make-cert-chain.pl produced 2 certificates" .
   " on standard output") or die "No point in testing anything else...";
my ($ca_cert_in_text, $user_cert_in_text) = @certs;

certificate_chain_ok($user_cert_in_text, [$ca_cert_in_text]);

my ($certdump, $err) =
  run_thru_openssl($user_cert_in_text, qw(x509 -noout -text));
diag($certdump) if $ENV{VERBOSE};
is($?, 0, "``openssl x509'' ran successfully")
  or die $err;

like($certdump, qr/12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF/i,
     "big hex serial");
like($certdump, qr/Issuer:.*Yoyodyne/, "issuer DN");
like($certdump, qr/Subject:.*test user cert/, "subject DN");
like($certdump, qr/basic.*constraints.*critical.*\n.*CA:FALSE/i,
     "Critical basicConstraints");
like($certdump, qr/example.com/, "subjectAltName 1/2");
like($certdump, qr/example.net/, "subjectAltName 2/2");
like($certdump, qr/Subject Key Identifier.*\n.*DE.AD.BE.EF/i,
     "subject key ID");
like($certdump, qr/Authority Key Identifier/i,
     "authority key ID");
unlike($certdump,
       qr/Authority Key Identifier.*critical.*\n.*DE.AD.BE.EF/i,
       "authority key ID *must not* be the same as subject key ID");
like($certdump, qr|Policy: 1.5.6.7.8|i, "policy identifiers 1/4");
like($certdump, qr|CPS: http://my.host.name/|i,
     "policy identifiers 2/4");
like($certdump, qr|Numbers: 1, 2, 3, 4|i,
     "policy identifiers 3/4");
like($certdump, qr|Explicit Text: Explicit Text Here|i,
     "policy identifiers 4/4");

if (dumpasn1_available()) {
  my $dumpasn1 = run_dumpasn1
    (scalar run_thru_openssl($user_cert_in_text, qw(x509 -outform der)));
  like($dumpasn1, qr/UTCTime.*2008.*\n.*GeneralizedTime.*2106/,
       "Proper detection of time format");
}


