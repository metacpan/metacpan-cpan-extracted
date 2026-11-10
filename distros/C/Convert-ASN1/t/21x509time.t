#!/usr/local/bin/perl

#
# Decode notBefore / notAfter of X.509 certificates into epoch values.
#
# UTCTime uses the window 1950 - 2049 for the two digit year (RFC 5280
# 4.1.2.5.1), GeneralizedTime carries the full year. The expected results
# must not depend on the current date.
#

use Convert::ASN1;

BEGIN { require './t/funcs.pl' }

my @certs = (
  # file                        notBefore                         notAfter
  # UTCTime 50 - 99 is 1950 - 1999
  [ 't/utctime_1950_1976.der', '500101000000Z',   -631152000,   '761231235959Z',   220924799    ],
  # GeneralizedTime 1900 - 1999
  [ 't/gentime_1900_1976.der', '19000101000000Z', -2208988800,  '19761231235959Z', 220924799    ],
  # GeneralizedTime 2900 - 9999
  [ 't/gentime_2900.der',      '260101000000Z',   1767225600,   '29000101000000Z', 29348006400  ],
  # GeneralizedTime 9999, "no well-defined expiration date" (RFC 5280 4.1.2.5)
  [ 't/gentime_9999.der',      '260101000000Z',   1767225600,   '99991231235959Z', 253402300799 ],
  # UTCTime 99 is 1999, UTCTime 49 is 2049
  [ 't/time_control.der',      '990101000000Z',   915148800,    '491231235959Z',   2524607999   ],
);

print "1..", 2 + 6 * @certs, "\n";

my $t = 1;

my $schema = <<ASN1;
  Time ::= CHOICE {
    utcTime      UTCTime,
    generalTime  GeneralizedTime }

  Validity ::= SEQUENCE {
    notBefore  Time,
    notAfter   Time }

  TBSCertificate ::= SEQUENCE {
    version               [0] EXPLICIT INTEGER OPTIONAL,
    serialNumber          INTEGER,
    signature             ANY,
    issuer                ANY,
    validity              Validity,
    subject               ANY,
    subjectPublicKeyInfo  ANY }

  Certificate ::= SEQUENCE {
    tbsCertificate      TBSCertificate,
    signatureAlgorithm  ANY,
    signature           BIT STRING }
ASN1

# default mode returns epoch values
my $asn = Convert::ASN1->new;
btest $t++, $asn->prepare($schema) or warn $asn->error;
my $parser = $asn->find(q(Certificate));

# raw mode returns the time strings as found in the certificate
my $raw = Convert::ASN1->new( decode => { time => q(raw) } );
btest $t++, $raw->prepare($schema) or warn $raw->error;
my $rawparser = $raw->find(q(Certificate));

foreach my $c (@certs) {
  my ($file, $nb_str, $nb_epoch, $na_str, $na_epoch) = @$c;

  print "# $file\n";

  open my $fh, '<', $file or die "cannot load test certificate $file\n";
  binmode $fh;
  my $der = do { local $/; <$fh> };
  close $fh;

  btest $t++, my $cert = $parser->decode($der) or warn $parser->error;
  btest $t++, my $rcert = $rawparser->decode($der) or warn $rawparser->error;

  my $v = $cert->{tbsCertificate}{validity};
  my $r = $rcert->{tbsCertificate}{validity};

  # make sure the certificate holds what we expect
  stest $t++, $nb_str, (values %{$r->{notBefore}})[0];
  stest $t++, $na_str, (values %{$r->{notAfter}})[0];

  ntest $t++, $nb_epoch, (values %{$v->{notBefore}})[0];
  ntest $t++, $na_epoch, (values %{$v->{notAfter}})[0];
}
