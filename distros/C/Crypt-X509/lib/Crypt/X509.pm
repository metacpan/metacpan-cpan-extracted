package Crypt::X509;
use Carp;
use strict;
use warnings;
use Convert::ASN1 qw(:io :debug);
require Exporter;
our @ISA         = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [qw()] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
#our @EXPORT      = qw(error new not_before not_after serial);
our $VERSION = '0.54';
my $parser = undef;
my $asn    = undef;
my $error  = undef;
our %oid2enchash = (
    '1.2.840.113549.1.1.1'  => { 'enc' => 'RSA' },
    '1.2.840.113549.1.1.2'  => { 'enc' => 'RSA', 'hash' => 'MD2' },
    '1.2.840.113549.1.1.3'  => { 'enc' => 'RSA', 'hash' => 'MD4' },
    '1.2.840.113549.1.1.4'  => { 'enc' => 'RSA', 'hash' => 'MD5' },
    '1.2.840.113549.1.1.5'  => { 'enc' => 'RSA', 'hash' => 'SHA1' },
    '1.2.840.113549.1.1.6'  => { 'enc' => 'OAEP' },
    '1.2.840.113549.1.1.11' => { 'enc' => 'RSA', 'hash' => 'SHA256' },
    '1.2.840.113549.1.1.12' => { 'enc' => 'RSA', 'hash' => 'SHA384' },
    '1.2.840.113549.1.1.13' => { 'enc' => 'RSA', 'hash' => 'SHA512' },
    '1.2.840.113549.1.1.14' => { 'enc' => 'RSA', 'hash' => 'SHA224' },
    '1.2.840.10045.2.1'     => { 'enc' => 'EC' },
);

our %oid2attr = (
    "2.5.4.3"                    => "CN",
    "2.5.4.4"                    => "SN",
    "2.5.4.42"                   => "GN",
    "2.5.4.5"                    => "serialNumber",
    "2.5.4.6"                    => "C",
    "2.5.4.7"                    => "L",
    "2.5.4.8"                    => "ST",
    '2.5.4.9'                    => 'streetAddress',
    "2.5.4.10"                   => "O",
    "2.5.4.11"                   => "OU",
    "1.2.840.113549.1.9.1"       => "emailAddress",
    '1.2.840.113549.1.9.2'       => 'unstructuredName',
    "0.9.2342.19200300.100.1.1"  => "UID",
    "0.9.2342.19200300.100.1.25" => "DC",
    "0.2.262.1.10.7.20"          => "nameDistinguisher",
    '2.5.4.12'    => 'title',
    '2.5.4.13'    => 'description',
    '2.5.4.14'    => 'searchGuide',
    '2.5.4.15'    => 'businessCategory',
    '2.5.4.16'    => 'postalAddress',
    '2.5.4.17'    => 'postalCode',
    '2.5.4.18'    => 'postOfficeBox',
    '2.5.4.19'    => 'physicalDeliveryOfficeName',
    '2.5.4.20'    => 'telephoneNumber',
    '2.5.4.23'    => 'facsimileTelephoneNumber',
    '2.5.4.41'    => 'name',
    '2.5.4.43'    => 'initials',
    '2.5.4.44'    => 'generationQualifier',
    '2.5.4.45'    => 'uniqueIdentifier',
    '2.5.4.46'    => 'dnQualifier',
    '2.5.4.51'    => 'houseIdentifier',
    '2.5.4.65'    => 'pseudonym',
);

=head1 NAME

Crypt::X509 - Parse a X.509 certificate

=head1 SYNOPSIS

 use Crypt::X509;

 $decoded = Crypt::X509->new( cert => $cert );

 $subject_email	= $decoded->subject_email;
 print "do not use after: ".gmtime($decoded->not_after)." GMT\n";

=head1 REQUIRES

Convert::ASN1

=head1 DESCRIPTION

B<Crypt::X509> parses X.509 certificates. Methods are provided for accessing most
certificate elements.

It is based on the generic ASN.1 module by Graham Barr, on the F<x509decode>
example by Norbert Klasen and contributions on the perl-ldap-dev-Mailinglist
by Chriss Ridd.

=head1 CONSTRUCTOR

=head2 new ( OPTIONS )

Creates and returns a parsed X.509 certificate hash, containing the parsed
contents. The data is organised as specified in RFC 2459.
By default only the first ASN.1 Layer is decoded. Nested decoding
is done automagically through the data access methods.

=over 4

=item cert =E<gt> $certificate

A variable containing the DER formatted certificate to be parsed
(eg. as stored in C<usercertificate;binary> attribute in an
LDAP-directory).

=back

  use Crypt::X509;
  use Data::Dumper;

  $decoded= Crypt::X509->new(cert => $cert);

  print Dumper($decoded);

=cut back

sub new {
    my ( $class, %args ) = @_;
    if ( !defined($parser) || $parser->error ) {
        $parser = _init();
    }
    my $self = $parser->decode( $args{'cert'} );
    $self->{"_error"} = $parser->error;
    bless( $self, $class );
    return $self;
}

=head1 METHODS

=head2 error

Returns the last error from parsing, C<undef> when no error occured.
This error is updated on deeper parsing with the data access methods.


  $decoded= Crypt::X509->new(cert => $cert);
  if ($decoded->error) {
    warn "Error on parsing Certificate:".$decoded->error;
  }

=cut back

sub error {
    my $self = shift;
    return $self->{"_error"};
}

=head1 DATA ACCESS METHODS

You can access all parsed data directly from the returned hash. For convenience
the following methods have been implemented to give quick access to the most-used
certificate attributes.

=head2 version

Returns the certificate's version as an integer.  NOTE that version is defined as
an Integer where 0 = v1, 1 = v2, and 2 = v3.

=cut back

sub version {
    my $self = shift;
    return $self->{tbsCertificate}{version};
}

=head2 version_string

Returns the certificate's version as a string value.

=cut back

sub version_string {
    my $self = shift;
    my $v    = $self->{tbsCertificate}{version};
    return "v1" if $v == 0;
    return "v2" if $v == 1;
    return "v3" if $v == 2;
}

=head2 serial

returns the serial number (integer or Math::BigInt Object, that gets automagic
evaluated in scalar context) from the certificate


  $decoded= Crypt::X509->new(cert => $cert);
  print "Certificate has serial number:".$decoded->serial."\n";

=cut back

sub serial {
    my $self = shift;
    return $self->{tbsCertificate}{serialNumber};
}

=head2 not_before

returns the GMT-timestamp of the certificate's beginning date of validity.
If the Certificate holds this Entry in utcTime, it is guaranteed by the
RFC to been correct.

As utcTime is limited to 32-bit values (like unix-timestamps) newer certificates
hold the timesamps as "generalTime"-entries. B<The contents of "generalTime"-entries
are not well defined in the RFC and
are returned by this module unmodified>, if no utcTime-entry is found.


  $decoded= Crypt::X509->new(cert => $cert);
  if ($decoded->notBefore < time()) {
    warn "Certificate: not yet valid!";
  }

=cut back

sub not_before {
    my $self = shift;
    if ( $self->{tbsCertificate}{validity}{notBefore}{utcTime} ) {
        return $self->{tbsCertificate}{validity}{notBefore}{utcTime};
    } elsif ( $self->{tbsCertificate}{validity}{notBefore}{generalTime} ) {
        return $self->{tbsCertificate}{validity}{notBefore}{generalTime};
    } else {
        return undef;
    }
}

=head2 not_after

returns the GMT-timestamp of the certificate's ending date of validity.
If the Certificate holds this Entry in utcTime, it is guaranteed by the
RFC to been correct.

As utcTime is limited to 32-bit values (like unix-timestamps) newer certificates
hold the timesamps as "generalTime"-entries. B<The contents of "generalTime"-entries
are not well defined in the RFC and
are returned by this module unmodified>, if no utcTime-entry is found.


  $decoded= Crypt::X509->new(cert => $cert);
  print "Certificate expires on ".gmtime($decoded->not_after)." GMT\n";

=cut back

sub not_after {
    my $self = shift;
    if ( $self->{tbsCertificate}{validity}{notAfter}{utcTime} ) {
        return $self->{tbsCertificate}{validity}{notAfter}{utcTime};
    } elsif ( $self->{tbsCertificate}{validity}{notAfter}{generalTime} ) {
        return $self->{tbsCertificate}{validity}{notAfter}{generalTime};
    } else {
        return undef;
    }
}

=head2 signature

Return's the certificate's signature in binary DER format.

=cut back

sub signature {
    my $self = shift;
    return $self->{signature}[0];
}

=head2 pubkey

Returns the certificate's public key in binary DER format.

=cut back

sub pubkey {
    my $self = shift;
    return $self->{tbsCertificate}{subjectPublicKeyInfo}{subjectPublicKey}[0];
}

=head2 pubkey_size

Returns the certificate's public key size.

=cut back

sub pubkey_size {
    my $self = shift;
    return $self->{tbsCertificate}{subjectPublicKeyInfo}{subjectPublicKey}[1];
}

=head2 pubkey_algorithm

Returns the algorithm as OID string which the public key was created with.

=cut back

sub pubkey_algorithm {
    my $self = shift;
    return $self->{tbsCertificate}{subjectPublicKeyInfo}{algorithm}{algorithm};
}

=head2 PubKeyAlg

returns the subject public key encryption algorithm (e.g. 'RSA') as string.

  $decoded= Crypt::X509->new(cert => $cert);
  print "Certificate public key is encrypted with:".$decoded->PubKeyAlg."\n";

  Example Output: Certificate public key is encrypted with: RSA

=cut back

sub PubKeyAlg {
    my $self = shift;
    return $oid2enchash{ $self->{tbsCertificate}{subjectPublicKeyInfo}{algorithm}{algorithm} }->{'enc'};
}

=head2 pubkey_components

If this certificate contains an RSA key, this function returns a
hashref { modulus => $m, exponent => $e) from that key; each value in
the hash will be an integer scalar or a Math::BigInt object.

For other pubkey types, it returns undef (implementations welcome!).

=cut back

sub pubkey_components {
    my $self = shift;
        if ($self->PubKeyAlg() eq 'RSA') {
          my $parser = _init('RSAPubKeyInfo');
          my $values = $parser->decode($self->{tbsCertificate}{subjectPublicKeyInfo}{subjectPublicKey}[0]);
          return $values;
        } else {
          return undef;
        }
}

=head2 sig_algorithm

Returns the certificate's signature algorithm as OID string

  $decoded= Crypt::X509->new(cert => $cert);
  print "Certificate signature is encrypted with:".$decoded->sig_algorithm."\n";>

  Example Output: Certificate signature is encrypted with: 1.2.840.113549.1.1.5

=cut back

sub sig_algorithm {
    my $self = shift;
    return $self->{tbsCertificate}{signature}{algorithm};
}

=head2 SigEncAlg

returns the signature encryption algorithm (e.g. 'RSA') as string.

  $decoded= Crypt::X509->new(cert => $cert);
  print "Certificate signature is encrypted with:".$decoded->SigEncAlg."\n";

  Example Output: Certificate signature is encrypted with: RSA

=cut back

sub SigEncAlg {
    my $self = shift;
    return $oid2enchash{ $self->{'signatureAlgorithm'}->{'algorithm'} }->{'enc'};
}

=head2 SigHashAlg

returns the signature hashing algorithm (e.g. 'SHA1') as string.

  $decoded= Crypt::X509->new(cert => $cert);
  print "Certificate signature is hashed with:".$decoded->SigHashAlg."\n";

  Example Output: Certificate signature is encrypted with: SHA1

=cut back

sub SigHashAlg {
    my $self = shift;
    return $oid2enchash{ $self->{'signatureAlgorithm'}->{'algorithm'} }->{'hash'};
}
#########################################################################
# accessors - subject
#########################################################################

=head2 Subject

returns a pointer to an array of strings containing subject nameparts of the
certificate. Attributenames for the most common Attributes are translated
from the OID-Numbers, unknown numbers are output verbatim.

  $decoded= Convert::ASN1::X509->new($cert);
  print "DN for this Certificate is:".join(',',@{$decoded->Subject})."\n";

=cut back
sub Subject {
    my $self = shift;
    my ( $i, $type );
    my $subjrdn = $self->{'tbsCertificate'}->{'subject'}->{'rdnSequence'};
    $self->{'tbsCertificate'}->{'subject'}->{'dn'} = [];
    my $subjdn = $self->{'tbsCertificate'}->{'subject'}->{'dn'};
    foreach my $subj ( @{$subjrdn} ) {
        foreach my $i ( @{$subj} ) {
            if ( $oid2attr{ $i->{'type'} } ) {
                $type = $oid2attr{ $i->{'type'} };
            } else {
                $type = $i->{'type'};
            }
            my @key = keys( %{ $i->{'value'} } );
            push @{$subjdn}, $type . "=" . $i->{'value'}->{ $key[0] };
        }
    }
    return $subjdn;
}


sub SubjectRaw {

    my $self = shift;
    my @subject;
    foreach my $rdn (@{$self->{'tbsCertificate'}->{'subject'}->{'rdnSequence'}}) {
        my @sequence = map {
            $_->{format} = (keys %{$_->{value}})[0];
            $_->{value} = (values %{$_->{value}})[0];
            $_;
        } @{$rdn};
        if (scalar @sequence > 1) {
            push @subject, \@sequence;
        } else {
            push @subject, $sequence[0];
        }
    }
    return \@subject;
}

sub _subject_part {
    my $self    = shift;
    my $oid     = shift;
    my $subjrdn = $self->{'tbsCertificate'}->{'subject'}->{'rdnSequence'};
    foreach my $subj ( @{$subjrdn} ) {
        foreach my $i ( @{$subj} ) {
            if ( $i->{'type'} eq $oid ) {
                my @key = keys( %{ $i->{'value'} } );
                return $i->{'value'}->{ $key[0] };
            }
        }
    }
    return undef;
}

=head2 subject_country

Returns the string value for subject's country (= the value with the
 OID 2.5.4.6 or in DN Syntax everything after C<C=>).
Only the first entry is returned. C<undef> if subject contains no country attribute.

=cut back

sub subject_country {
    my $self = shift;
    return _subject_part( $self, '2.5.4.6' );
}

=head2 subject_locality

Returns the string value for subject's locality (= the value with the
OID 2.5.4.7 or in DN Syntax everything after C<l=>).
Only the first entry is returned. C<undef> if subject contains no locality attribute.

=cut back

sub subject_locality {
       my $self = shift;
       return _subject_part( $self, '2.5.4.7' );
}

=head2 subject_state

Returns the string value for subject's state or province (= the value with the
OID 2.5.4.8 or in DN Syntax everything after C<S=>).
Only the first entry is returned. C<undef> if subject contains no state attribute.

=cut back

sub subject_state {
    my $self = shift;
    return _subject_part( $self, '2.5.4.8' );
}

=head2 subject_org

Returns the string value for subject's organization (= the value with the
OID 2.5.4.10 or in DN Syntax everything after C<O=>).
Only the first entry is returned. C<undef> if subject contains no organization attribute.

=cut back

sub subject_org {
    my $self = shift;
    return _subject_part( $self, '2.5.4.10' );
}

=head2 subject_ou

Returns the string value for subject's organizational unit (= the value with the
OID 2.5.4.11 or in DN Syntax everything after C<OU=>).
Only the first entry is returned. C<undef> if subject contains no organization attribute.

=cut back

sub subject_ou {
    my $self = shift;
    return _subject_part( $self, '2.5.4.11' );
}

=head2 subject_cn

Returns the string value for subject's common name (= the value with the
OID 2.5.4.3 or in DN Syntax everything after C<CN=>).
Only the first entry is returned. C<undef> if subject contains no common name attribute.

=cut back

sub subject_cn {
    my $self = shift;
    return _subject_part( $self, '2.5.4.3' );
}

=head2 subject_email

Returns the string value for subject's email address (= the value with the
OID 1.2.840.113549.1.9.1 or in DN Syntax everything after C<emailAddress=>).
Only the first entry is returned. C<undef> if subject contains no email attribute.

=cut back

sub subject_email {
    my $self = shift;
    return _subject_part( $self, '1.2.840.113549.1.9.1' );
}
#########################################################################
# accessors - issuer
#########################################################################

=head2 Issuer

returns a pointer to an array of strings building the DN of the certificate
issuer (= the DN of the CA). Attributenames for the most common Attributes
are translated from the OID-Numbers, unknown numbers are output verbatim.

  $decoded= Crypt::X509->new($cert);
  print "Certificate was issued by:".join(',',@{$decoded->Issuer})."\n";

=cut back
sub Issuer {
    my $self = shift;
    my ( $i, $type );
    my $issuerdn = $self->{'tbsCertificate'}->{'issuer'}->{'rdnSequence'};
    $self->{'tbsCertificate'}->{'issuer'}->{'dn'} = [];
    my $issuedn = $self->{'tbsCertificate'}->{'issuer'}->{'dn'};
    foreach my $issue ( @{$issuerdn} ) {
        foreach my $i ( @{$issue} ) {
            if ( $oid2attr{ $i->{'type'} } ) {
                $type = $oid2attr{ $i->{'type'} };
            } else {
                $type = $i->{'type'};
            }
            my @key = keys( %{ $i->{'value'} } );
            push @{$issuedn}, $type . "=" . $i->{'value'}->{ $key[0] };
        }
    }
    return $issuedn;
}

sub _issuer_part {
    my $self      = shift;
    my $oid       = shift;
    my $issuerrdn = $self->{'tbsCertificate'}->{'issuer'}->{'rdnSequence'};
    foreach my $issue ( @{$issuerrdn} ) {
        foreach my $i ( @{$issue} ) {
            if ( $i->{'type'} eq $oid ) {
                my @key = keys( %{ $i->{'value'} } );
                return $i->{'value'}->{ $key[0] };
            }
        }
    }
    return undef;
}

=head2 issuer_cn

Returns the string value for issuer's common name (= the value with the
OID 2.5.4.3 or in DN Syntax everything after C<CN=>).
Only the first entry is returned. C<undef> if issuer contains no common name attribute.

=cut back

sub issuer_cn {
    my $self = shift;
    return _issuer_part( $self, '2.5.4.3' );
}

=head2 issuer_country

Returns the string value for issuer's country (= the value with the
 OID 2.5.4.6 or in DN Syntax everything after C<C=>).
Only the first entry is returned. C<undef> if issuer contains no country attribute.

=cut back

sub issuer_country {
    my $self = shift;
    return _issuer_part( $self, '2.5.4.6' );
}

=head2 issuer_state

Returns the string value for issuer's state or province (= the value with the
OID 2.5.4.8 or in DN Syntax everything after C<S=>).
Only the first entry is returned. C<undef> if issuer contains no state attribute.

=cut back

sub issuer_state {
    my $self = shift;
    return _issuer_part( $self, '2.5.4.8' );
}

=head2 issuer_locality

Returns the string value for issuer's locality (= the value with the
OID 2.5.4.7 or in DN Syntax everything after C<L=>).
Only the first entry is returned. C<undef> if issuer contains no locality attribute.

=cut back

sub issuer_locality {
    my $self = shift;
    return _issuer_part( $self, '2.5.4.7' );
}

=head2 issuer_org

Returns the string value for issuer's organization (= the value with the
OID 2.5.4.10 or in DN Syntax everything after C<O=>).
Only the first entry is returned. C<undef> if issuer contains no organization attribute.

=cut back

sub issuer_org {
    my $self = shift;
    return _issuer_part( $self, '2.5.4.10' );
}

=head2 issuer_email

Returns the string value for issuer's email address (= the value with the
OID 1.2.840.113549.1.9.1 or in DN Syntax everything after C<E=>).
Only the first entry is returned. C<undef> if issuer contains no email attribute.

=cut back

sub issuer_email {
    my $self = shift;
    return _issuer_part( $self, '1.2.840.113549.1.9.1' );
}
#########################################################################
# accessors - extensions (automate this)
#########################################################################

=head2 KeyUsage

returns a pointer to an array of strings describing the valid Usages
for this certificate. C<undef> is returned, when the extension is not set in the
certificate.

If the extension is marked critical, this is also reported.

  $decoded= Crypt::X509->new(cert => $cert);
  print "Allowed usages for this Certificate are:\n".join("\n",@{$decoded->KeyUsage})."\n";

  Example Output:
  Allowed usages for this Certificate are:
  critical
  digitalSignature
  keyEncipherment
  dataEncipherment

=cut back
sub KeyUsage {
    my $self = shift;
    my $ext;
    my $exts = $self->{'tbsCertificate'}->{'extensions'};
    if ( !defined $exts ) { return undef; }
    ;    # no extensions in certificate
    foreach $ext ( @{$exts} ) {
        if ( $ext->{'extnID'} eq '2.5.29.15' ) {    #OID for keyusage
            my $parsKeyU = _init('KeyUsage');         # get a parser for this
            my $keyusage = $parsKeyU->decode( $ext->{'extnValue'} );    # decode the value
            if ( $parsKeyU->error ) {
                $self->{"_error"} = $parsKeyU->error;
                return undef;
            }
            my $keyu = unpack( "n", ${$keyusage}[0] . ${$keyusage}[1] ) & 0xff80;
            $ext->{'usage'} = [];
            if ( $ext->{'critical'} ) { push @{ $ext->{'usage'} }, "critical"; }           # mark as critical, if appropriate
            if ( $keyu & 0x8000 )     { push @{ $ext->{'usage'} }, "digitalSignature"; }
            if ( $keyu & 0x4000 )     { push @{ $ext->{'usage'} }, "nonRepudiation"; }
            if ( $keyu & 0x2000 )     { push @{ $ext->{'usage'} }, "keyEncipherment"; }
            if ( $keyu & 0x1000 )     { push @{ $ext->{'usage'} }, "dataEncipherment"; }
            if ( $keyu & 0x0800 )     { push @{ $ext->{'usage'} }, "keyAgreement"; }
            if ( $keyu & 0x0400 )     { push @{ $ext->{'usage'} }, "keyCertSign"; }
            if ( $keyu & 0x0200 )     { push @{ $ext->{'usage'} }, "cRLSign"; }
            if ( $keyu & 0x0100 )     { push @{ $ext->{'usage'} }, "encipherOnly"; }
            if ( $keyu & 0x0080 )     { push @{ $ext->{'usage'} }, "decipherOnly"; }
            return $ext->{'usage'};
        }
    }
    return undef;    # keyusage extension not found
}

=head2 ExtKeyUsage

returns a pointer to an array of ExtKeyUsage strings (or OIDs for unknown OIDs) or
C<undef> if the extension is not filled. OIDs of the following ExtKeyUsages are known:
serverAuth, clientAuth, codeSigning, emailProtection, timeStamping, OCSPSigning

If the extension is marked critical, this is also reported.

  $decoded= Crypt::X509->new($cert);
  print "ExtKeyUsage extension of this Certificates is: ", join(", ", @{$decoded->ExtKeyUsage}), "\n";

  Example Output: ExtKeyUsage extension of this Certificates is: critical, serverAuth

=cut back
our %oid2extkeyusage = (
      '1.3.6.1.5.5.7.3.1' => 'serverAuth',
      '1.3.6.1.5.5.7.3.2' => 'clientAuth',
      '1.3.6.1.5.5.7.3.3' => 'codeSigning',
      '1.3.6.1.5.5.7.3.4' => 'emailProtection',
      '1.3.6.1.5.5.7.3.8' => 'timeStamping',
      '1.3.6.1.5.5.7.3.9' => 'OCSPSigning',
);

sub ExtKeyUsage {
    my $self = shift;
    my $ext;
    my $exts = $self->{'tbsCertificate'}->{'extensions'};
    if ( !defined $exts ) { return undef; }
    ;    # no extensions in certificate
    foreach $ext ( @{$exts} ) {
        if ( $ext->{'extnID'} eq '2.5.29.37' ) {    #OID for ExtKeyUsage
            return $ext->{'oids'} if defined $ext->{'oids'};
            my $parsExtKeyUsage = _init('ExtKeyUsageSyntax');       # get a parser for this
            my $oids            = $parsExtKeyUsage->decode( $ext->{'extnValue'} );    # decode the value
            if ( $parsExtKeyUsage->error ) {
                $self->{"_error"} = $parsExtKeyUsage->error;
                return undef;
            }
            $ext->{'oids'} = [ map { $oid2extkeyusage{$_} || $_ } @$oids ];
            if ( $ext->{'critical'} ) { unshift @{ $ext->{'oids'} }, "critical"; }    # mark as critical, if appropriate
            return $ext->{'oids'};
        }
    }
    return undef;
}

=head2 SubjectAltName

returns a pointer to an array of strings containing alternative Subjectnames or
C<undef> if the extension is not filled. Usually this Extension holds the e-Mail
address for person-certificates or DNS-Names for server certificates.

It also pre-pends the field type (ie rfc822Name) to the returned value.

  $decoded= Crypt::X509->new($cert);
  print "E-Mail or Hostnames in this Certificates is/are:", join(", ", @{$decoded->SubjectAltName}), "\n";

  Example Output: E-Mail or Hostnames in this Certificates is/are: rfc822Name=user@server.com

=cut back

sub SubjectAltName {
    my $self = shift;
    my $ext;
    my $exts = $self->{'tbsCertificate'}->{'extensions'};
    if ( !defined $exts ) { return undef; }
    ;    # no extensions in certificate
    foreach $ext ( @{$exts} ) {
        if ( $ext->{'extnID'} eq '2.5.29.17' ) {    #OID for SubjectAltName
            my $parsSubjAlt = _init('SubjectAltName');      # get a parser for this
            my $altnames    = $parsSubjAlt->decode( $ext->{'extnValue'} );    # decode the value
            if ( $parsSubjAlt->error ) {
                $self->{"_error"} = $parsSubjAlt->error;
                return undef;
            }
            $ext->{'names'} = [];
            foreach my $name ( @{$altnames} ) {
                foreach my $value ( keys %{$name} ) {
                    push @{ $ext->{'names'} }, "$value=" . $name->{$value};
                }
            }
            return $ext->{'names'};
        }
    }
    return undef;
}

=head2 DecodedSubjectAltNames

Returns a pointer to an array of strings containing all the alternative subject name
extensions.

Each such extension is represented as a decoded ASN.1 value, i.e. a pointer to a list
of pointers to objects, each object having a single key with the type of the alternative
name and a value specific to that type.

Example return value:

  [
    [
      {
        'directoryName' => {
          'rdnSequence' => [
            [
              {
                'value' => { 'utf8String' => 'example' },
                'type' => '2.5.4.3'
              }
            ]
          ]
        }
      },
      {
        'dNSName' => 'example.com'
      }
    ]
  ]

=cut back

sub DecodedSubjectAltNames {
    my $self = shift;
    my @sans = ();
    my $exts = $self->{'tbsCertificate'}->{'extensions'};
    foreach my $ext ( @{$exts} ) {
        if ( $ext->{'extnID'} eq '2.5.29.17' ) { #OID for subjectAltName
            my $parsSubjAlt = _init('SubjectAltName');
            my $altnames = $parsSubjAlt->decode( $ext->{'extnValue'} );
            if ( $parsSubjAlt->error ) {
                $self->{'_error'} = $parsSubjAlt->error;
                return undef;
            }
            push @sans, $altnames;
        }
    }
    return \@sans;
}

#########################################################################
# accessors - authorityCertIssuer
#########################################################################
sub _AuthorityKeyIdentifier {
    my $self = shift;
    my $ext;
    my $exts = $self->{'tbsCertificate'}->{'extensions'};
    if ( !defined $exts ) { return undef; }
    ;    # no extensions in certificate
    if ( defined $self->{'tbsCertificate'}{'AuthorityKeyIdentifier'} ) {
        return ( $self->{'tbsCertificate'}{'AuthorityKeyIdentifier'} );
    }
    foreach $ext ( @{$exts} ) {
        if ( $ext->{'extnID'} eq '2.5.29.35' ) {    #OID for AuthorityKeyIdentifier
            my $pars = _init('AuthorityKeyIdentifier');    # get a parser for this
            $self->{'tbsCertificate'}{'AuthorityKeyIdentifier'} = $pars->decode( $ext->{'extnValue'} );    # decode the value
            if ( $pars->error ) {
                $self->{"_error"} = $pars->error;
                return undef;
            }
            return $self->{'tbsCertificate'}{'AuthorityKeyIdentifier'};
        }
    }
    return undef;
}

=head2 authorityCertIssuer

returns a pointer to an array of strings building the DN of the Authority Cert
Issuer. Attributenames for the most common Attributes
are translated from the OID-Numbers, unknown numbers are output verbatim.
undef if the extension is not set in the certificate.

  $decoded= Crypt::X509->new($cert);
  print "Certificate was authorised by:".join(',',@{$decoded->authorityCertIssuer})."\n";

=cut back

sub authorityCertIssuer {
    my $self = shift;
    my ( $i, $type );
    my $rdn = _AuthorityKeyIdentifier($self);
    if ( !defined($rdn) ) {
        return (undef);    # we do not have that extension
    } else {
        $rdn = $rdn->{'authorityCertIssuer'}[0]->{'directoryName'};
    }
    $rdn->{'dn'} = [];
    my $dn = $rdn->{'dn'};
    $rdn = $rdn->{'rdnSequence'};
    foreach my $r ( @{$rdn} ) {
        $i = @{$r}[0];
        if ( $oid2attr{ $i->{'type'} } ) {
            $type = $oid2attr{ $i->{'type'} };
        } else {
            $type = $i->{'type'};
        }
        my @key = keys( %{ $i->{'value'} } );
        push @{$dn}, $type . "=" . $i->{'value'}->{ $key[0] };
    }
    return $dn;
}

sub _authcert_part {
    my $self = shift;
    my $oid  = shift;
    my $rdn  = _AuthorityKeyIdentifier($self);
    if ( !defined($rdn) ) {
        return (undef);    # we do not have that extension
    } else {
        $rdn = $rdn->{'authorityCertIssuer'}[0]->{'directoryName'}->{'rdnSequence'};
    }
    foreach my $r ( @{$rdn} ) {
        my $i = @{$r}[0];
        if ( $i->{'type'} eq $oid ) {
            my @key = keys( %{ $i->{'value'} } );
            return $i->{'value'}->{ $key[0] };
        }
    }
    return undef;
}

=head2 authority_serial

Returns the authority's certificate serial number.

=cut back

sub authority_serial {
    my $self = shift;
    return ( $self->_AuthorityKeyIdentifier )->{authorityCertSerialNumber};
}

=head2 key_identifier

Returns the authority key identifier or undef if it is a rooted cert

=cut back

sub key_identifier {
    my $self = shift;
    if ( defined $self->_AuthorityKeyIdentifier ) { return ( $self->_AuthorityKeyIdentifier )->{keyIdentifier}; }
    return undef;
}

=head2 authority_cn

Returns the authority's ca.

=cut back

sub authority_cn {
    my $self = shift;
    return _authcert_part( $self, '2.5.4.3' );
}

=head2 authority_country

Returns the authority's country.

=cut back

sub authority_country {
    my $self = shift;
    return _authcert_part( $self, '2.5.4.6' );
}

=head2 authority_state

Returns the authority's state.

=cut back

sub authority_state {
    my $self = shift;
    return _authcert_part( $self, '2.5.4.8' );
}

=head2 authority_locality

Returns the authority's locality.

=cut back

sub authority_locality {
    my $self = shift;
    return _authcert_part( $self, '2.5.4.7' );
}

=head2 authority_org

Returns the authority's organization.

=cut back

sub authority_org {
    my $self = shift;
    return _authcert_part( $self, '2.5.4.10' );
}

=head2 authority_email

Returns the authority's email.

=cut back

sub authority_email {
    my $self = shift;
    return _authcert_part( $self, '1.2.840.113549.1.9.1' );
}

=head2 CRLDistributionPoints

Returns the CRL distribution points as an array of strings (with one value usually)

=cut back

sub CRLDistributionPoints {
    my $self = shift;
    my $ext;
    my $exts = $self->{'tbsCertificate'}->{'extensions'};
    if ( !defined $exts ) { return undef; }
    ;    # no extensions in certificate
    foreach $ext ( @{$exts} ) {
        if ( $ext->{'extnID'} eq '2.5.29.31' ) {    #OID for cRLDistributionPoints
            my $crlp   = _init('cRLDistributionPoints');          # get a parser for this
            my $points = $crlp->decode( $ext->{'extnValue'} );    # decode the value
            $points = $points->[0]->{'distributionPoint'}->{'fullName'};
            if ( $crlp->error ) {
                $self->{"_error"} = $crlp->error;
                return undef;
            }
            foreach my $name ( @{$points} ) {
                push @{ $ext->{'crlpoints'} }, $name->{'uniformResourceIdentifier'};
            }
            return $ext->{'crlpoints'};
        }
    }
    return undef;
}

=head2 CRLDistributionPoints2

Returns the CRL distribution points as an array of hashes (allowing for some variations)

=cut back

# newer CRL
sub CRLDistributionPoints2 {
    my $self = shift;
    my %CDPs;
    my $dp_cnt = 0;    # this is a counter used to show which CDP a particular value is listed in
    my $extensions = $self->{'tbsCertificate'}->{'extensions'};
    if ( !defined $extensions ) { return undef; }
    ;                  # no extensions in certificate
    for my $extension ( @{$extensions} ) {
        if ( $extension->{'extnID'} eq '2.5.29.31' ) {    # OID for ARRAY of cRLDistributionPoints
            my $parser = _init('cRLDistributionPoints');                  # get a parser for CDPs
            my $points = $parser->decode( $extension->{'extnValue'} );    # decode the values (returns an array)
            for my $each_dp ( @{$points} ) {            # this loops through multiple "distributionPoint" values
                $dp_cnt++;
                for my $each_fullName ( @{ $each_dp->{'distributionPoint'}->{'fullName'} } )
                {                     # this loops through multiple "fullName" values
                    if ( exists $each_fullName->{directoryName} ) {

      # found a rdnSequence
      my $rdn = join ',', reverse @{ my_CRL_rdn( $each_fullName->{directoryName}->{rdnSequence} ) };
      push @{ $CDPs{$dp_cnt} }, "Directory Address: $rdn";
                    } elsif ( exists $each_fullName->{uniformResourceIdentifier} ) {

      # found a URI
      push @{ $CDPs{$dp_cnt} }, "URL: " . $each_fullName->{uniformResourceIdentifier};
                    } else {

      # found some other type of CDP value
      # return undef;
                    }
                }
            }
            return %CDPs;
        }
    }
    return undef;
}

sub my_CRL_rdn {
    my $crl_rdn = shift;    # this should be the passed in 'rdnSequence' array
    my ( $i, $type );
    my $crl_dn = [];
    for my $part ( @{$crl_rdn} ) {
        $i = @{$part}[0];
        if ( $oid2attr{ $i->{'type'} } ) {
            $type = $oid2attr{ $i->{'type'} };
        } else {
            $type = $i->{'type'};
        }
        my @key = keys( %{ $i->{'value'} } );
        push @{$crl_dn}, $type . "=" . $i->{'value'}->{ $key[0] };
    }
    return $crl_dn;
}

=head2 CertificatePolicies

Returns the CertificatePolicies as an array of strings

=cut back

# CertificatePolicies (another extension)
sub CertificatePolicies {
    my $self = shift;
    my $extension;
    my $CertPolicies = [];
    my $extensions   = $self->{'tbsCertificate'}->{'extensions'};
    if ( !defined $extensions ) { return undef; }
    ;    # no extensions in certificate
    for $extension ( @{$extensions} ) {
        if ( $extension->{'extnID'} eq '2.5.29.32' ) {    # OID for CertificatePolicies
            my $parser   = _init('CertificatePolicies');                    # get a parser for this
            my $policies = $parser->decode( $extension->{'extnValue'} );    # decode the value
            for my $policy ( @{$policies} ) {
                for my $key ( keys %{$policy} ) {
                    push @{$CertPolicies}, "$key=" . $policy->{$key};
                }
            }
            return $CertPolicies;
        }
    }
    return undef;
}

=head2 EntrustVersionInfo

Returns the EntrustVersion as a string

    print "Entrust Version: ", $decoded->EntrustVersion, "\n";

    Example Output: Entrust Version: V7.0

=cut back

# EntrustVersion (another extension)
sub EntrustVersion {
    my $self = shift;
    my $extension;
    my $extensions = $self->{'tbsCertificate'}->{'extensions'};
    if ( !defined $extensions ) { return undef; }
    ;    # no extensions in certificate
    for $extension ( @{$extensions} ) {
        if ( $extension->{'extnID'} eq '1.2.840.113533.7.65.0' ) {    # OID for EntrustVersionInfo
            my $parser  = _init('EntrustVersionInfo');                     # get a parser for this
            my $entrust = $parser->decode( $extension->{'extnValue'} );    # decode the value
            return $entrust->{'entrustVers'};

            # not doing anything with the EntrustInfoFlags BIT STRING (yet)
            # $entrust->{'entrustInfoFlags'}
        }
    }
    return undef;
}

=head2 SubjectDirectoryAttributes

Returns the SubjectDirectoryAttributes as an array of key = value pairs, to include a data type

    print "Subject Directory Attributes: ", join( ', ' , @{ $decoded->SubjectDirectoryAttributes } ), "\n";

    Example Output: Subject Directory Attributes: 1.2.840.113533.7.68.29 = 7 (integer)

=cut back

# SubjectDirectoryAttributes (another extension)
sub SubjectDirectoryAttributes {
    my $self = shift;
    my $extension;
    my $attributes = [];
    my $extensions = $self->{'tbsCertificate'}->{'extensions'};
    if ( !defined $extensions ) { return undef; }
    ;    # no extensions in certificate
    for $extension ( @{$extensions} ) {
        if ( $extension->{'extnID'} eq '2.5.29.9' ) {    # OID for SubjectDirectoryAttributes
            my $parser            = _init('SubjectDirectoryAttributes');             # get a parser for this
            my $subject_dir_attrs = $parser->decode( $extension->{'extnValue'} );    # decode the value
            for my $type ( @{$subject_dir_attrs} ) {
                for my $value ( @{ $type->{'values'} } ) {
                    for my $key ( keys %{$value} ) {
      push @{$attributes}, $type->{'type'} . " = " . $value->{$key} . " ($key)";
                    }
                }
            }
            return $attributes;
        }
    }
    return undef;
}

=head2 BasicConstraints

Returns the BasicConstraints as an array and the criticallity pre-pended.

=cut back

# BasicConstraints (another extension)
sub BasicConstraints {
    my $self = shift;
    my $extension;
    my $constraints = [];
    my $extensions  = $self->{'tbsCertificate'}->{'extensions'};
    if ( !defined $extensions ) { return undef; }
    ;    # no extensions in certificate
    for $extension ( @{$extensions} ) {
        if ( $extension->{'extnID'} eq '2.5.29.19' ) {    # OID for BasicConstraints
            if ( $extension->{'critical'} ) { push @{$constraints}, "critical"; }    # mark this as critical as appropriate
            my $parser            = _init('BasicConstraints');     # get a parser for this
            my $basic_constraints = $parser->decode( $extension->{'extnValue'} );    # decode the value
            for my $key ( keys %{$basic_constraints} ) {
                push @{$constraints}, "$key = " . $basic_constraints->{$key};
            }
            return $constraints;
        }
    }
    return undef;
}

=head2 subject_keyidentifier

Returns the subject key identifier from the extensions.

=cut back

# subject_keyidentifier (another extension)
sub subject_keyidentifier {
    my $self = shift;
    return $self->_SubjectKeyIdentifier;
}

# _SubjectKeyIdentifier (another extension)
sub _SubjectKeyIdentifier {
    my $self       = shift;
    my $extensions = $self->{'tbsCertificate'}->{'extensions'};
    if ( !defined $extensions ) { return undef; }
    ;    # no extensions in certificate
    if ( defined $self->{'tbsCertificate'}{'SubjectKeyIdentifier'} ) {
        return ( $self->{'tbsCertificate'}{'SubjectKeyIdentifier'} );
    }
    for my $extension ( @{$extensions} ) {
        if ( $extension->{'extnID'} eq '2.5.29.14' ) {    # OID for SubjectKeyIdentifier
            my $parser = _init('SubjectKeyIdentifier');    # get a parser for this
            $self->{'tbsCertificate'}{'SubjectKeyIdentifier'} = $parser->decode( $extension->{'extnValue'} );    # decode the value
            if ( $parser->error ) {
                $self->{"_error"} = $parser->error;
                return undef;
            }
            return $self->{'tbsCertificate'}{'SubjectKeyIdentifier'};
        }
    }
    return undef;
}

=head2 SubjectInfoAccess

Returns the SubjectInfoAccess as an array of hashes with key=value pairs.

        print "Subject Info Access: ";
        if ( defined $decoded->SubjectInfoAccess ) {
            my %SIA = $decoded->SubjectInfoAccess;
            for my $key ( keys %SIA ) {
                print "\n\t$key: \n\t";
                print join( "\n\t" , @{ $SIA{$key} } ), "\n";
            }
        } else { print "\n" }

    Example Output:
        Subject Info Access:
            1.3.6.1.5.5.7.48.5:
            uniformResourceIdentifier = http://pki.treas.gov/root_sia.p7c
            uniformResourceIdentifier = ldap://ldap.treas.gov/ou=US%20Treasury%20Root%20CA,ou=Certification%20Authorities,ou=Department%20of%20the%20Treasury,o=U.S.%20Government,c=US?cACertificate;binary,crossCertificatePair;binary

=cut back

# SubjectInfoAccess (another extension)
sub SubjectInfoAccess {
    my $self = shift;
    my $extension;
    my %SIA;
    my $extensions = $self->{'tbsCertificate'}->{'extensions'};
    if ( !defined $extensions ) { return undef; }
    ;    # no extensions in certificate
    for $extension ( @{$extensions} ) {
        if ( $extension->{'extnID'} eq '1.3.6.1.5.5.7.1.11' ) {    # OID for SubjectInfoAccess
            my $parser              = _init('SubjectInfoAccessSyntax');                # get a parser for this
            my $subject_info_access = $parser->decode( $extension->{'extnValue'} );    # decode the value
            for my $sia ( @{$subject_info_access} ) {
                for my $key ( keys %{ $sia->{'accessLocation'} } ) {
                    push @{ $SIA{ $sia->{'accessMethod'} } }, "$key = " . $sia->{'accessLocation'}{$key};
                }
            }
            return %SIA;
        }
    }
    return undef;
}


=head2 PGPExtension

Returns the creation timestamp of the corresponding OpenPGP key.
(see http://www.imc.org/ietf-openpgp/mail-archive/msg05320.html)

        print "PGPExtension: ";
        if ( defined $decoded->PGPExtension ) {
            my $creationtime = $decoded->PGPExtension;
            printf "\n\tcorresponding OpenPGP Creation Time: ", $creationtime, "\n";
                }

    Example Output:
        PGPExtension:
                    whatever

=cut back

# PGPExtension (another extension)
sub PGPExtension {
    my $self = shift;
    my $extension;
    my $extensions = $self->{'tbsCertificate'}->{'extensions'};
    if ( !defined $extensions ) { return undef; }
    ;    # no extensions in certificate
    for $extension ( @{$extensions} ) {
        if ( $extension->{'extnID'} eq '1.3.6.1.4.1.3401.8.1.1' ) {    # OID for PGPExtension
            my $parser              = _init('PGPExtension');                # get a parser for this
            my $pgpextension = $parser->decode( $extension->{'extnValue'} );    # decode the value
      if ($pgpextension->{version} != 0) {
        $self->{"_error"} = sprintf("got PGPExtension version %d. We only know how to deal with v1 (0)", $pgpextension->{version});
      } else {
        foreach my $timetype ('generalTime', 'utcTime') {
          return $pgpextension->{keyCreation}->{$timetype}
            if exists $pgpextension->{keyCreation}->{$timetype};
        }
      }
        }
    }
    return undef;
}

#######################################################################
# internal functions
#######################################################################
sub _init {
    my $what = shift;
    if ( ( !defined $what ) || ( '' eq $what ) ) { $what = 'Certificate' }
    if ( !defined $asn ) {
        $asn = Convert::ASN1->new;
        $asn->prepare(<<ASN1);
-- ASN.1 from RFC2459 and X.509(2001)
-- Adapted for use with Convert::ASN1
-- Id: x509decode,v 1.1 2002/02/10 16:41:28 gbarr Exp

-- attribute data types --

Attribute ::= SEQUENCE {
    type			AttributeType,
    values			SET OF AttributeValue
        -- at least one value is required --
    }

AttributeType ::= OBJECT IDENTIFIER

AttributeValue ::= DirectoryString  --ANY

AttributeTypeAndValue ::= SEQUENCE {
    type			AttributeType,
    value			AttributeValue
    }


-- naming data types --

Name ::= CHOICE { -- only one possibility for now
    rdnSequence		RDNSequence
    }

RDNSequence ::= SEQUENCE OF RelativeDistinguishedName

DistinguishedName ::= RDNSequence

RelativeDistinguishedName ::=
    SET OF AttributeTypeAndValue  --SET SIZE (1 .. MAX) OF


-- Directory string type --

DirectoryString ::= CHOICE {
    teletexString		TeletexString,  --(SIZE (1..MAX)),
    printableString		PrintableString,  --(SIZE (1..MAX)),
    bmpString		BMPString,  --(SIZE (1..MAX)),
    universalString		UniversalString,  --(SIZE (1..MAX)),
    utf8String		UTF8String,  --(SIZE (1..MAX)),
    ia5String		IA5String,  --added for EmailAddress,
    integer			INTEGER
    }


-- certificate and CRL specific structures begin here

Certificate ::= SEQUENCE  {
    tbsCertificate		TBSCertificate,
    signatureAlgorithm	AlgorithmIdentifier,
    signature		BIT STRING
    }

TBSCertificate  ::=  SEQUENCE  {
    version		    [0] EXPLICIT Version OPTIONAL,  --DEFAULT v1
    serialNumber		CertificateSerialNumber,
    signature		AlgorithmIdentifier,
    issuer			Name,
    validity		Validity,
    subject			Name,
    subjectPublicKeyInfo	SubjectPublicKeyInfo,
    issuerUniqueID	    [1] IMPLICIT UniqueIdentifier OPTIONAL,
        -- If present, version shall be v2 or v3
    subjectUniqueID	    [2] IMPLICIT UniqueIdentifier OPTIONAL,
        -- If present, version shall be v2 or v3
    extensions	    [3] EXPLICIT Extensions OPTIONAL
        -- If present, version shall be v3
    }

Version ::= INTEGER  --{  v1(0), v2(1), v3(2)  }

CertificateSerialNumber ::= INTEGER

Validity ::= SEQUENCE {
    notBefore		Time,
    notAfter		Time
    }

Time ::= CHOICE {
    utcTime			UTCTime,
    generalTime		GeneralizedTime
    }

UniqueIdentifier ::= BIT STRING

SubjectPublicKeyInfo ::= SEQUENCE {
    algorithm		AlgorithmIdentifier,
    subjectPublicKey	BIT STRING
    }


RSAPubKeyInfo ::=   SEQUENCE {
    modulus INTEGER,
    exponent INTEGER
    }

Extensions ::= SEQUENCE OF Extension  --SIZE (1..MAX) OF Extension

Extension ::= SEQUENCE {
    extnID			OBJECT IDENTIFIER,
    critical		BOOLEAN OPTIONAL,  --DEFAULT FALSE,
    extnValue		OCTET STRING
    }

AlgorithmIdentifier ::= SEQUENCE {
    algorithm		OBJECT IDENTIFIER,
    parameters		ANY OPTIONAL
    }


--extensions

AuthorityKeyIdentifier ::= SEQUENCE {
      keyIdentifier             [0] KeyIdentifier            OPTIONAL,
      authorityCertIssuer       [1] GeneralNames             OPTIONAL,
      authorityCertSerialNumber [2] CertificateSerialNumber  OPTIONAL }
    -- authorityCertIssuer and authorityCertSerialNumber shall both
    -- be present or both be absent

KeyIdentifier ::= OCTET STRING

SubjectKeyIdentifier ::= KeyIdentifier

-- key usage extension OID and syntax

-- id-ce-keyUsage OBJECT IDENTIFIER ::=  { id-ce 15 }

KeyUsage ::= BIT STRING --{
--      digitalSignature        (0),
--      nonRepudiation          (1),
--      keyEncipherment         (2),
--      dataEncipherment        (3),
--      keyAgreement            (4),
--      keyCertSign             (5),
--      cRLSign                 (6),
--      encipherOnly            (7),
--      decipherOnly            (8) }


-- private key usage period extension OID and syntax

-- id-ce-privateKeyUsagePeriod OBJECT IDENTIFIER ::=  { id-ce 16 }

PrivateKeyUsagePeriod ::= SEQUENCE {
     notBefore       [0]     GeneralizedTime OPTIONAL,
     notAfter        [1]     GeneralizedTime OPTIONAL }
     -- either notBefore or notAfter shall be present

-- certificate policies extension OID and syntax
-- id-ce-certificatePolicies OBJECT IDENTIFIER ::=  { id-ce 32 }

CertificatePolicies ::= SEQUENCE OF PolicyInformation

PolicyInformation ::= SEQUENCE {
     policyIdentifier   CertPolicyId,
     policyQualifiers   SEQUENCE OF
             PolicyQualifierInfo OPTIONAL }

CertPolicyId ::= OBJECT IDENTIFIER

PolicyQualifierInfo ::= SEQUENCE {
       policyQualifierId  PolicyQualifierId,
       qualifier        ANY } --DEFINED BY policyQualifierId }

-- Implementations that recognize additional policy qualifiers shall
-- augment the following definition for PolicyQualifierId

PolicyQualifierId ::=
     OBJECT IDENTIFIER --( id-qt-cps | id-qt-unotice )

-- CPS pointer qualifier

CPSuri ::= IA5String

-- user notice qualifier

UserNotice ::= SEQUENCE {
     noticeRef        NoticeReference OPTIONAL,
     explicitText     DisplayText OPTIONAL}

NoticeReference ::= SEQUENCE {
     organization     DisplayText,
     noticeNumbers    SEQUENCE OF INTEGER }

DisplayText ::= CHOICE {
     visibleString    VisibleString  ,
     bmpString        BMPString      ,
     utf8String       UTF8String      }


-- policy mapping extension OID and syntax
-- id-ce-policyMappings OBJECT IDENTIFIER ::=  { id-ce 33 }

PolicyMappings ::= SEQUENCE OF SEQUENCE {
     issuerDomainPolicy      CertPolicyId,
     subjectDomainPolicy     CertPolicyId }


-- subject alternative name extension OID and syntax
-- id-ce-subjectAltName OBJECT IDENTIFIER ::=  { id-ce 17 }

SubjectAltName ::= GeneralNames

GeneralNames ::= SEQUENCE OF GeneralName

GeneralName ::= CHOICE {
     otherName     [0]     AnotherName,
     rfc822Name    [1]     IA5String,
     dNSName       [2]     IA5String,
     x400Address                     [3]     ANY, --ORAddress,
     directoryName                   [4]     Name,
     ediPartyName                    [5]     EDIPartyName,
     uniformResourceIdentifier       [6]     IA5String,
     iPAddress     [7]     OCTET STRING,
     registeredID                    [8]     OBJECT IDENTIFIER }

EntrustVersionInfo ::= SEQUENCE {
              entrustVers  GeneralString,
              entrustInfoFlags EntrustInfoFlags }

EntrustInfoFlags::= BIT STRING --{
--      keyUpdateAllowed
--      newExtensions     (1),  -- not used
--      pKIXCertificate   (2) } -- certificate created by pkix

-- AnotherName replaces OTHER-NAME ::= TYPE-IDENTIFIER, as
-- TYPE-IDENTIFIER is not supported in the 88 ASN.1 syntax

AnotherName ::= SEQUENCE {
     type    OBJECT IDENTIFIER,
     value      [0] EXPLICIT ANY } --DEFINED BY type-id }

EDIPartyName ::= SEQUENCE {
     nameAssigner            [0]     DirectoryString OPTIONAL,
     partyName               [1]     DirectoryString }


-- issuer alternative name extension OID and syntax
-- id-ce-issuerAltName OBJECT IDENTIFIER ::=  { id-ce 18 }

IssuerAltName ::= GeneralNames


-- id-ce-subjectDirectoryAttributes OBJECT IDENTIFIER ::=  { id-ce 9 }

SubjectDirectoryAttributes ::= SEQUENCE OF Attribute


-- basic constraints extension OID and syntax
-- id-ce-basicConstraints OBJECT IDENTIFIER ::=  { id-ce 19 }

BasicConstraints ::= SEQUENCE {
     cA    BOOLEAN OPTIONAL, --DEFAULT FALSE,
     pathLenConstraint       INTEGER OPTIONAL }


-- name constraints extension OID and syntax
-- id-ce-nameConstraints OBJECT IDENTIFIER ::=  { id-ce 30 }

NameConstraints ::= SEQUENCE {
     permittedSubtrees       [0]     GeneralSubtrees OPTIONAL,
     excludedSubtrees        [1]     GeneralSubtrees OPTIONAL }

GeneralSubtrees ::= SEQUENCE OF GeneralSubtree

GeneralSubtree ::= SEQUENCE {
     base                    GeneralName,
     minimum         [0]     BaseDistance OPTIONAL, --DEFAULT 0,
     maximum         [1]     BaseDistance OPTIONAL }

BaseDistance ::= INTEGER


-- policy constraints extension OID and syntax
-- id-ce-policyConstraints OBJECT IDENTIFIER ::=  { id-ce 36 }

PolicyConstraints ::= SEQUENCE {
     requireExplicitPolicy           [0] SkipCerts OPTIONAL,
     inhibitPolicyMapping            [1] SkipCerts OPTIONAL }

SkipCerts ::= INTEGER


-- CRL distribution points extension OID and syntax
-- id-ce-cRLDistributionPoints     OBJECT IDENTIFIER  ::=  {id-ce 31}

cRLDistributionPoints  ::= SEQUENCE OF DistributionPoint

DistributionPoint ::= SEQUENCE {
     distributionPoint       [0]     DistributionPointName OPTIONAL,
     reasons                 [1]     ReasonFlags OPTIONAL,
     cRLIssuer               [2]     GeneralNames OPTIONAL }

DistributionPointName ::= CHOICE {
     fullName                [0]     GeneralNames,
     nameRelativeToCRLIssuer [1]     RelativeDistinguishedName }

ReasonFlags ::= BIT STRING --{
--     unused                  (0),
--     keyCompromise           (1),
--     cACompromise            (2),
--     affiliationChanged      (3),
--     superseded              (4),
--     cessationOfOperation    (5),
--     certificateHold         (6),
--     privilegeWithdrawn      (7),
--     aACompromise            (8) }


-- extended key usage extension OID and syntax
-- id-ce-extKeyUsage OBJECT IDENTIFIER ::= {id-ce 37}

ExtKeyUsageSyntax ::= SEQUENCE OF KeyPurposeId

KeyPurposeId ::= OBJECT IDENTIFIER

-- extended key purpose OIDs
-- id-kp-serverAuth      OBJECT IDENTIFIER ::= { id-kp 1 }
-- id-kp-clientAuth      OBJECT IDENTIFIER ::= { id-kp 2 }
-- id-kp-codeSigning     OBJECT IDENTIFIER ::= { id-kp 3 }
-- id-kp-emailProtection OBJECT IDENTIFIER ::= { id-kp 4 }
-- id-kp-ipsecEndSystem  OBJECT IDENTIFIER ::= { id-kp 5 }
-- id-kp-ipsecTunnel     OBJECT IDENTIFIER ::= { id-kp 6 }
-- id-kp-ipsecUser       OBJECT IDENTIFIER ::= { id-kp 7 }
-- id-kp-timeStamping    OBJECT IDENTIFIER ::= { id-kp 8 }

-- authority info access

-- id-pe-authorityInfoAccess OBJECT IDENTIFIER ::= { id-pe 1 }

AuthorityInfoAccessSyntax  ::=
        SEQUENCE OF AccessDescription --SIZE (1..MAX) OF AccessDescription

AccessDescription  ::=  SEQUENCE {
        accessMethod          OBJECT IDENTIFIER,
        accessLocation        GeneralName  }

-- subject info access

-- id-pe-subjectInfoAccess OBJECT IDENTIFIER ::= { id-pe 11 }

SubjectInfoAccessSyntax  ::=
        SEQUENCE OF AccessDescription --SIZE (1..MAX) OF AccessDescription

-- pgp creation time

PGPExtension ::= SEQUENCE {
       version             Version, -- DEFAULT v1(0)
       keyCreation         Time
}
ASN1
    }
    my $self = $asn->find($what);
    return $self;
}

=head1 SEE ALSO

See the examples of C<Convert::ASN1> and the <perl-ldap@perl.org> Mailing List.
An example on how to load certificates can be found in F<t\Crypt-X509.t>.

=head1 ACKNOWLEDGEMENTS

This module is based on the x509decode script, which was contributed to
Convert::ASN1 in 2002 by Norbert Klasen.

=head1 AUTHORS

Mike Jackson <mj@sci.fi>,
Alexander Jung <alexander.w.jung@gmail.com>,
Duncan Segrest <duncan@gigageek.info>
Oliver Welter  <owelter@whiterabbitsecurity.com>

=head1 COPYRIGHT

Copyright (c) 2005 Mike Jackson <mj@sci.fi>.
Copyright (c) 2001-2002 Norbert Klasen, DAASI International GmbH.

All rights reserved. This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
1;
__END__
