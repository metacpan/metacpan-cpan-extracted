#!/usr/local/bin/perl

#
# Misc tests from github reported issues
#

use Convert::ASN1;
BEGIN { require 't/funcs.pl' }

print "1..2\n";

{    # github issue 8

  my $hexdata = "30 53 30 51 30 4f 30 4d 30 4b 30 09 06 05 2b 0e
                 03 02 1a 05 00 04 14 a0 72 0e a0 6a 7c 62 02 54
                 f2 a8 f5 9d d2 7b a4 f3 b7 2f a4 04 14 b0 b0 4a
                 fd 1c 75 28 f8 1c 61 aa 13 f6 fa c1 90 3d 6b 16
                 a3 02 12 11 21 bc 57 28 6f 30 08 db 49 63 f6 ae
                 89 3a de f6 d1 ff e0";
  $hexdata =~ s/ //g;
  $hexdata =~ s/\n//g;

# parse ASN.1 descriptions
  my $asn = Convert::ASN1->new;
  $asn->prepare(<<ASN1) or die "prepare: ", $asn->error;
  OCSPRequest     ::=     SEQUENCE {
      tbsRequest                  TBSRequest,
      optionalSignature   [0]     EXPLICIT ANY OPTIONAL }

  TBSRequest      ::=     SEQUENCE {
      version             [0]     EXPLICIT INTEGER OPTIONAL,
      requestorName       [1]     EXPLICIT ANY OPTIONAL,
      requestList                 SEQUENCE OF Request,
      requestExtensions   [2]     EXPLICIT ANY OPTIONAL }

  Request         ::=     SEQUENCE {
      reqCert                     CertID,
      singleRequestExtensions     [0] EXPLICIT ANY OPTIONAL }

  CertID          ::=     SEQUENCE {
      hashAlgorithm       ANY,
      issuerNameHash      OCTET STRING, -- Hash of Issuer's DN
      issuerKeyHash       OCTET STRING, -- Hash of Issuers public key
      serialNumber        INTEGER }
ASN1

  my $asn_ocspreq = $asn->find('OCSPRequest');

  my $OCSPREQDER = pack("H*", $hexdata);

  my $ocspreq = $asn_ocspreq->decode($OCSPREQDER);
  my $err = $asn_ocspreq->error;
  $err =~ s/ at .*line \d.*//s if $err;
  stest 1, "decode error 85 87", $err;

  btest 2, !!$asn_ocspreq->decode(substr($OCSPREQDER, 0, -2));

}


