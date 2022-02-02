#
# Crypt::PKCS10
#
# ABSTRACT: parse PKCS #10 certificate requests
#
# This software is copyright (c) 2014 by Gideon Knocke.
# Copyright (c) 2016 Gideon Knocke, Timothe Litt
#
# See LICENSE for details.
#

package Crypt::PKCS10;

use strict;
use warnings;
use Carp;

use overload( q("") => 'as_string' );

use Convert::ASN1( qw/:tag :const/ );
use Encode ();
use MIME::Base64;
use Scalar::Util ();

our $VERSION = '2.003';

my $apiVersion = undef;  # 0 for compatibility.  1 for prefered
my $error;

# N.B. Names are exposed in the API.
#      %shortnames follows & depends on (some) values.
# When adding OIDs, re-generate the documentation (see "for MAINTAINER" below)
#
# New OIDs don't need the [ ] syntax, which is [ prefered name, deprecated name ]
# Some of the deprecated names are used in the ASN.1 definition. and in the $self
# structure, which unfortunately is exposed with the attributes() method.
# Dealing with the deprecated names causes some messy code.

my %oids = (
    '2.5.4.6'                       => 'countryName',
    '2.5.4.8'                       => 'stateOrProvinceName',
    '2.5.4.10'                      => 'organizationName',
    '2.5.4.11'                      => 'organizationalUnitName',
    '2.5.4.3'                       => 'commonName',
    '1.2.840.113549.1.9.1'          => 'emailAddress',
    '1.2.840.113549.1.9.2'          => 'unstructuredName',
    '1.2.840.113549.1.9.7'          => 'challengePassword',
    '1.2.840.113549.1.9.8'          => 'unstructuredAddress',
    '1.2.840.113549.1.1.1'          => [ 'rsaEncryption', 'RSA encryption' ],
    '1.2.840.113549.1.1.5'          => [ 'sha1WithRSAEncryption', 'SHA1 with RSA encryption' ],
    '1.2.840.113549.1.1.4'          => [ 'md5WithRSAEncryption', 'MD5 with RSA encryption' ],
    '1.2.840.113549.1.1.10'         => 'rsassaPss',
    '1.2.840.113549.1.9.14'         => 'extensionRequest',
    '1.3.6.1.4.1.311.13.2.3'        => 'OS_Version',                   # Microsoft
    '1.3.6.1.4.1.311.13.2.2'        => 'EnrollmentCSP',                # Microsoft
    '1.3.6.1.4.1.311.21.20'         => 'ClientInformation',            # Microsoft REQUEST_CLIENT_INFO
    '1.3.6.1.4.1.311.21.7'          => 'certificateTemplate',          # Microsoft
    '2.5.29.37'                     => [ 'extKeyUsage', 'EnhancedKeyUsage' ],
    '2.5.29.15'                     => [ 'keyUsage', 'KeyUsage' ],
    '1.3.6.1.4.1.311.21.10'         => 'ApplicationCertPolicies',      # Microsoft APPLICATION_CERT_POLICIES
    '2.5.29.14'                     => [ 'subjectKeyIdentifier', 'SubjectKeyIdentifier' ],
    '2.5.29.17'                     => 'subjectAltName',
    '1.3.6.1.4.1.311.20.2'          => 'certificateTemplateName',      # Microsoft
    '2.16.840.1.113730.1.1'         => 'netscapeCertType',
    '2.16.840.1.113730.1.2'         => 'netscapeBaseUrl',
    '2.16.840.1.113730.1.4'         => 'netscapeCaRevocationUrl',
    '2.16.840.1.113730.1.7'         => 'netscapeCertRenewalUrl',
    '2.16.840.1.113730.1.8'         => 'netscapeCaPolicyUrl',
    '2.16.840.1.113730.1.12'        => 'netscapeSSLServerName',
    '2.16.840.1.113730.1.13'        => 'netscapeComment',

    #untested
    '2.5.29.19'                     => [ 'basicConstraints', 'Basic Constraints' ],
    '1.2.840.10040.4.1'             => [ 'dsa', 'DSA' ],
    '1.2.840.10040.4.3'             => [ 'dsaWithSha1', 'DSA with SHA1' ],
    '1.2.840.10045.2.1'             => 'ecPublicKey',
    '1.2.840.10045.4.3.1'           => 'ecdsa-with-SHA224',
    '1.2.840.10045.4.3.2'           => 'ecdsa-with-SHA256',
    '1.2.840.10045.4.3.3'           => 'ecdsa-with-SHA384',
    '1.2.840.10045.4.3.4'           => 'ecdsa-with-SHA512',
    '1.3.36.3.3.2.8.1.1.1'          => 'brainpoolP160r1',
    '1.3.36.3.3.2.8.1.1.2'          => 'brainpoolP160t1',
    '1.3.36.3.3.2.8.1.1.3'          => 'brainpoolP192r1',
    '1.3.36.3.3.2.8.1.1.4'          => 'brainpoolP192t1',
    '1.3.36.3.3.2.8.1.1.5'          => 'brainpoolP224r1',
    '1.3.36.3.3.2.8.1.1.6'          => 'brainpoolP224t1',
    '1.3.36.3.3.2.8.1.1.7'          => 'brainpoolP256r1',
    '1.3.36.3.3.2.8.1.1.8'          => 'brainpoolP256t1',
    '1.3.36.3.3.2.8.1.1.9'          => 'brainpoolP320r1',
    '1.3.36.3.3.2.8.1.1.10'         => 'brainpoolP320t1',
    '1.3.36.3.3.2.8.1.1.11'         => 'brainpoolP384r1',
    '1.3.36.3.3.2.8.1.1.12'         => 'brainpoolP384t1',
    '1.3.36.3.3.2.8.1.1.13'         => 'brainpoolP512r1',
    '1.3.36.3.3.2.8.1.1.14'         => 'brainpoolP512t1',
    '1.2.840.10045.3.1.1'           => 'secp192r1',
    '1.3.132.0.1'                   => 'sect163k1',
    '1.3.132.0.15'                  => 'sect163r2',
    '1.3.132.0.33'                  => 'secp224r1',
    '1.3.132.0.26'                  => 'sect233k1',
    '1.3.132.0.27'                  => 'sect233r1',
    '1.3.132.0.16'                  => 'sect283k1',
    '1.3.132.0.17'                  => 'sect283r1',
    '1.2.840.10045.3.1.7'           => 'secp256r1',
    '1.3.132.0.34'                  => 'secp384r1',
    '1.3.132.0.36'                  => 'sect409k1',
    '1.3.132.0.37'                  => 'sect409r1',
    '1.3.132.0.35'                  => 'secp521r1',
    '1.3.132.0.38'                  => 'sect571k1',
    '1.3.132.0.39'                  => 'sect571r1',
#not std yet    '1.3.6.1.4.1.3029.1.5.1'        => 'curve25519', # GNU TLS
#   '1.3.6.1.4.1.11591.7'           => 'curve25519', #ID josefsson-pkix-newcurves-00
#   '1.3.6.1.4.1.11591.8'           => 'curve448', #ID josefsson-pkix-newcurves-00
    '0.9.2342.19200300.100.1.25'    => 'domainComponent',
    '0.9.2342.19200300.100.1.1'     => 'userID',
    '2.5.4.7'                       => 'localityName',
    '1.2.840.113549.1.1.11'         => [ 'sha256WithRSAEncryption', 'SHA-256 with RSA encryption' ],
    '1.2.840.113549.1.1.12'         => 'sha384WithRSAEncryption',
    '1.2.840.113549.1.1.13'         => [ 'sha512WithRSAEncryption', 'SHA-512 with RSA encryption' ],
    '1.2.840.113549.1.1.14'         => 'sha224WithRSAEncryption',
    '1.2.840.113549.1.1.2'          => [ 'md2WithRSAEncryption', 'MD2 with RSA encryption' ],
    '1.2.840.113549.1.1.3'          => 'md4WithRSAEncryption',
    '1.2.840.113549.1.1.6'          => 'rsaOAEPEncryptionSET',
    '1.2.840.113549.1.1.7'          => 'RSAES-OAEP',
    '1.2.840.113549.1.9.15'         => [ 'smimeCapabilities', 'SMIMECapabilities' ],
    '1.3.14.3.2.29'                 => [ 'sha1WithRSAEncryption', 'SHA1 with RSA signature' ],
    '1.3.6.1.4.1.311.13.1'          => 'RENEWAL_CERTIFICATE',          # Microsoft
    '1.3.6.1.4.1.311.13.2.1'        => 'ENROLLMENT_NAME_VALUE_PAIR',   # Microsoft
    '1.3.6.1.4.1.311.13.2.2'        => 'ENROLLMENT_CSP_PROVIDER',      # Microsoft
    '1.3.6.1.4.1.311.2.1.14'        => 'CERT_EXTENSIONS',              # Microsoft
    '1.3.6.1.5.2.3.5'               => [ 'keyPurposeKdc', 'KDC Authentication' ],
    '1.3.6.1.5.5.7.9.5'             => 'countryOfResidence',
    '2.16.840.1.101.3.4.2.1'        => [ 'sha256', 'SHA-256' ],
    '2.16.840.1.101.3.4.2.2'        => [ 'sha384', 'SHA-384' ],
    '2.16.840.1.101.3.4.2.3'        => [ 'sha512', 'SHA-512' ],
    '2.16.840.1.101.3.4.2.4'        => [ 'sha224', 'SHA-224' ],
    '2.16.840.1.101.3.4.3.1'        => 'dsaWithSha224',
    '2.16.840.1.101.3.4.3.2'        => 'dsaWithSha256',
    '2.16.840.1.101.3.4.3.3'        => 'dsaWithSha384',
    '2.16.840.1.101.3.4.3.4'        => 'dsaWithSha512',
    '2.5.4.12'                      => [ 'title', 'Title' ],
    '2.5.4.13'                      => [ 'description', 'Description' ],
    '2.5.4.14'                      => 'searchGuide',
    '2.5.4.15'                      => 'businessCategory',
    '2.5.4.16'                      => 'postalAddress',
    '2.5.4.17'                      => 'postalCode',
    '2.5.4.18'                      => 'postOfficeBox',
    '2.5.4.19',                     => 'physicalDeliveryOfficeName',
    '2.5.4.20',                     => 'telephoneNumber',
    '2.5.4.23',                     => 'facsimileTelephoneNumber',
    '2.5.4.4'                       => [ 'surname', 'Surname' ],
    '2.5.4.41'                      => [ 'name', 'Name' ],
    '2.5.4.42'                      => 'givenName',
    '2.5.4.43'                      => 'initials',
    '2.5.4.44'                      => 'generationQualifier',
    '2.5.4.45'                      => 'uniqueIdentifier',
    '2.5.4.46'                      => 'dnQualifier',
    '2.5.4.51'                      => 'houseIdentifier',
    '2.5.4.65'                      => 'pseudonym',
    '2.5.4.5'                       => 'serialNumber',
    '2.5.4.9'                       => 'streetAddress',
    '2.5.29.32'                     => 'certificatePolicies',
    '2.5.29.32.0'                   => 'anyPolicy',
    '1.3.6.1.5.5.7.2.1'             => 'CPS',
    '1.3.6.1.5.5.7.2.2'             => 'userNotice',
);

my %variantNames;

foreach (keys %oids) {
    my $val = $oids{$_};
    if( ref $val ) {
	$variantNames{$_} = $val;                   # OID to [ new, trad ]
	$variantNames{$val->[0]} = $val->[1];       # New name to traditional for lookups
	$variantNames{'$' . $val->[1]} = $val->[0]; # \$Traditional to new
	$oids{$_} = $val->[!$apiVersion || 0];
    }
}

my %oid2extkeyusage = (
                '1.3.6.1.5.5.7.3.1'        => 'serverAuth',
                '1.3.6.1.5.5.7.3.2'        => 'clientAuth',
                '1.3.6.1.5.5.7.3.3'        => 'codeSigning',
                '1.3.6.1.5.5.7.3.4'        => 'emailProtection',
                '1.3.6.1.5.5.7.3.8'        => 'timeStamping',
                '1.3.6.1.5.5.7.3.9'        => 'OCSPSigning',

		'1.3.6.1.5.5.7.3.21'       => 'sshClient',
		'1.3.6.1.5.5.7.3.22'       => 'sshServer',

		# Microsoft usages

                '1.3.6.1.4.1.311.10.3.1'   => 'msCTLSign',
                '1.3.6.1.4.1.311.10.3.2'   => 'msTimeStamping',
                '1.3.6.1.4.1.311.10.3.3'   => 'msSGC',
                '1.3.6.1.4.1.311.10.3.4'   => 'msEFS',
                '1.3.6.1.4.1.311.10.3.4.1' => 'msEFSRecovery',
                '1.3.6.1.4.1.311.10.3.5'   => 'msWHQLCrypto',
                '1.3.6.1.4.1.311.10.3.6'   => 'msNT5Crypto',
                '1.3.6.1.4.1.311.10.3.7'   => 'msOEMWHQLCrypto',
                '1.3.6.1.4.1.311.10.3.8'   => 'msEmbeddedNTCrypto',
                '1.3.6.1.4.1.311.10.3.9'   => 'msRootListSigner',
                '1.3.6.1.4.1.311.10.3.10'  => 'msQualifiedSubordination',
                '1.3.6.1.4.1.311.10.3.11'  => 'msKeyRecovery',
                '1.3.6.1.4.1.311.10.3.12'  => 'msDocumentSigning',
                '1.3.6.1.4.1.311.10.3.13'  => 'msLifetimeSigning',
                '1.3.6.1.4.1.311.10.3.14'  => 'msMobileDeviceSoftware',

                '1.3.6.1.4.1.311.2.1.21'   => 'msCodeInd',
                '1.3.6.1.4.1.311.2.1.22'   => 'msCodeCom',
                '1.3.6.1.4.1.311.20.2.2'   => 'msSmartCardLogon',


	        # Netscape
                '2.16.840.1.113730.4.1'    => 'nsSGC',
);

my %shortnames = (
		  countryName            => 'C',
		  stateOrProvinceName    => 'ST',
		  organizationName       => 'O',
		  organizationalUnitName => 'OU',
		  commonName             => 'CN',
#		  emailAddress           => 'E', # Deprecated & not recognized by some software
		  domainComponent        => 'DC',
		  localityName           => 'L',
		  userID                 => 'UID',
		  surname                => 'SN',
		  givenName              => 'GN',
);

our $schema = <<ASN1
    DirectoryString ::= CHOICE {
      teletexString   TeletexString,
      printableString PrintableString,
      bmpString       BMPString,
      universalString UniversalString,
      utf8String      UTF8String,
      ia5String       IA5String,
      integer         INTEGER}

    Algorithms ::= ANY

    Name ::= SEQUENCE OF RelativeDistinguishedName
    RelativeDistinguishedName ::= SET OF AttributeTypeAndValue
    AttributeTypeAndValue ::= SEQUENCE {
      type  OBJECT IDENTIFIER,
      value DirectoryString}

    Attributes ::= SET OF Attribute
    Attribute ::= SEQUENCE {
      type   OBJECT IDENTIFIER,
      values SET OF ANY}


    AlgorithmIdentifier ::= SEQUENCE {
      algorithm  OBJECT IDENTIFIER,
      parameters Algorithms OPTIONAL}

    SubjectPublicKeyInfo ::= SEQUENCE {
      algorithm        AlgorithmIdentifier,
      subjectPublicKey BIT STRING}

    --- Certificate Request ---

    CertificationRequest ::= SEQUENCE {
      certificationRequestInfo  CertificationRequestInfo,
      signatureAlgorithm        AlgorithmIdentifier,
      signature                 BIT STRING},

    CertificationRequestInfo ::= SEQUENCE {
      version       INTEGER ,
      subject       Name OPTIONAL,
      subjectPKInfo SubjectPublicKeyInfo,
      attributes    [0] Attributes OPTIONAL}

    --- Extensions ---

    BasicConstraints ::= SEQUENCE {
        cA                  BOOLEAN OPTIONAL, -- DEFAULT FALSE,
        pathLenConstraint   INTEGER OPTIONAL}

    OS_Version ::= IA5String
    emailAddress ::= IA5String

    EnrollmentCSP ::= SEQUENCE {
        KeySpec     INTEGER,
        Name        BMPString,
        Signature   BIT STRING}

    ENROLLMENT_CSP_PROVIDER ::= SEQUENCE { -- MSDN
        keySpec     INTEGER,
        cspName     BMPString,
        signature   BIT STRING}

    ENROLLMENT_NAME_VALUE_PAIR ::= EnrollmentNameValuePair -- MSDN: SEQUENCE OF

    EnrollmentNameValuePair ::= SEQUENCE { -- MSDN
         name       BMPString,
         value      BMPString}

    ClientInformation ::= SEQUENCE { -- MSDN
        clientId       INTEGER,
        MachineName    UTF8String,
        UserName       UTF8String,
        ProcessName    UTF8String}

    extensionRequest ::= SEQUENCE OF Extension
    Extension ::= SEQUENCE {
      extnID    OBJECT IDENTIFIER,
      critical  BOOLEAN OPTIONAL,
      extnValue OCTET STRING}

    SubjectKeyIdentifier ::= OCTET STRING

    certificateTemplate ::= SEQUENCE {
       templateID              OBJECT IDENTIFIER,
       templateMajorVersion    INTEGER OPTIONAL, -- (0..4294967295)
       templateMinorVersion    INTEGER OPTIONAL} -- (0..4294967295)

    EnhancedKeyUsage ::= SEQUENCE OF OBJECT IDENTIFIER
    KeyUsage ::= BIT STRING
    netscapeCertType ::= BIT STRING

    ApplicationCertPolicies ::= SEQUENCE OF PolicyInformation -- Microsoft

    PolicyInformation ::= SEQUENCE {
        policyIdentifier   OBJECT IDENTIFIER,
        policyQualifiers   SEQUENCE OF PolicyQualifierInfo OPTIONAL}

    PolicyQualifierInfo ::= SEQUENCE {
       policyQualifierId    OBJECT IDENTIFIER,
       qualifier            ANY}

    certificatePolicies ::= SEQUENCE OF certPolicyInformation -- RFC 3280

    certPolicyInformation ::= SEQUENCE {
        policyIdentifier    CertPolicyId,
        policyQualifier     SEQUENCE OF certPolicyQualifierInfo OPTIONAL}

    CertPolicyId ::= OBJECT IDENTIFIER

    certPolicyQualifierInfo ::= SEQUENCE {
        policyQualifierId CertPolicyQualifierId,
        qualifier         ANY DEFINED BY policyQualifierId}

    CertPolicyQualifierId ::= OBJECT IDENTIFIER

    CertPolicyQualifier ::= CHOICE {
        cPSuri     CPSuri,
        userNotice UserNotice }

    CPSuri ::= IA5String

    UserNotice ::= SEQUENCE {
        noticeRef     NoticeReference OPTIONAL,
        explicitText  DisplayText OPTIONAL}

    NoticeReference ::= SEQUENCE {
        organization     DisplayText,
        noticeNumbers    SEQUENCE OF INTEGER }

    DisplayText ::= CHOICE {
        ia5String        IA5String,
        visibleString    VisibleString,
        bmpString        BMPString,
        utf8String       UTF8String }

    unstructuredName ::= CHOICE {
        Ia5String       IA5String,
        directoryString DirectoryString}

    challengePassword ::= DirectoryString

    subjectAltName ::= SEQUENCE OF GeneralName

    GeneralName ::= CHOICE {
         otherName                       [0]     AnotherName,
         rfc822Name                      [1]     IA5String,
         dNSName                         [2]     IA5String,
         x400Address                     [3]     ANY, --ORAddress,
         directoryName                   [4]     Name,
         ediPartyName                    [5]     EDIPartyName,
         uniformResourceIdentifier       [6]     IA5String,
         iPAddress                       [7]     OCTET STRING,
         registeredID                    [8]     OBJECT IDENTIFIER}

    AnotherName ::= SEQUENCE {
         type           OBJECT IDENTIFIER,
         value      [0] EXPLICIT ANY }

    EDIPartyName ::= SEQUENCE {
         nameAssigner            [0]     DirectoryString OPTIONAL,
         partyName               [1]     DirectoryString }

    certificateTemplateName ::= CHOICE {
        octets          OCTET STRING,
        directoryString DirectoryString}

    rsaKey ::= SEQUENCE {
        modulus         INTEGER,
        publicExponent  INTEGER}

    dsaKey  ::= INTEGER

    dsaPars ::= SEQUENCE {
        P               INTEGER,
        Q               INTEGER,
        G               INTEGER}

    eccName ::= OBJECT IDENTIFIER

    ecdsaSigValue ::= SEQUENCE {
        r               INTEGER,
        s               INTEGER}

    rsassaPssParam ::= SEQUENCE {
        digestAlgorithm     [0] EXPLICIT AlgorithmIdentifier,
        maskGenAlgorithm    ANY,
        saltLength          [2] EXPLICIT INTEGER OPTIONAL,
        trailerField        ANY OPTIONAL}
ASN1
;

my %name2oid;

# For generating documentation, not part of API

sub _cmpOID {
    my @a = split( /\./, $a );
    my @b = split( /\./, $b );

    while( @a && @b ) {
        my $c = shift @a <=> shift @b;
        return $c if( $c );
    }
    return @a <=> @b;
}

sub __listOIDs {
    my $class = shift;
    my ( $hash ) = @_;

    my @max = (0) x 3;
    foreach my $oid ( keys %$hash ) {
	my $len;

	$len = length $oid;
	$max[0] = $len if( $len > $max[0] );
	if( exists $variantNames{$oid} ) {
	    $len = length $variantNames{$oid}[0];
	    $max[1] = $len if( $len > $max[1] );
	    $len = length $variantNames{$oid}[1];
	    $max[2] = $len if( $len > $max[2] );
	} else {
	    $len = length $hash->{$oid};
	    $max[1] = $len if( $len > $max[1] );
	}
    }

    printf( " %-*s %-*s %s\n %s %s %s\n", $max[0], 'OID',
	                                  $max[1], 'Name (API v1)', 'Old Name (API v0)',
	                                  '-' x $max[0], '-' x $max[1], '-' x $max[2] );

    foreach my $oid ( sort _cmpOID keys %$hash ) {
	printf( " %-*s %-*s", $max[0], $oid, $max[1], (exists $variantNames{$oid})?
		                                         $variantNames{$oid}[0]: $hash->{$oid} );
	printf( " (%-s)", $variantNames{$oid}[1] ) if( exists $variantNames{$oid} );
	print( "\n" );
    }
    return;
}

sub _listOIDs {
    my $class = shift;

    $class->setAPIversion(1);
    $class-> __listOIDs( { %oids, %oid2extkeyusage } );

    return;
}

sub setAPIversion {
    my( $class, $version ) = @_;

    croak( substr(($error = "Wrong number of arguments\n"), 0, -1) ) unless( @_ == 2 && defined $class && !ref $class );
    $version = 0 unless( defined $version );
    croak( substr(($error = "Unsupported API version $version\n"), 0, -1) ) unless( $version >= 0 && $version <= 1 );
    $apiVersion = $version;

    $version = !$version || 0;

    foreach (keys %variantNames) {
	$oids{$_} = $variantNames{$_}[$version] if( /^\d/ ); # Map OID to selected name
    }
    %name2oid = reverse (%oids, %oid2extkeyusage);

    return 1;
}

sub getAPIversion {
    my( $class ) = @_;

    croak( "Class not specified for getAPIversion()" ) unless( defined $class );

    return $class->{_apiVersion} if( ref $class && $class->isa( __PACKAGE__ ) );

    return $apiVersion;
}

sub name2oid {
    my $class = shift;
    my( $oid ) = @_;

    croak( "Class not specifed for name2oid()" ) unless( defined $class );

    return unless( defined $oid && defined $apiVersion && $apiVersion > 0 );

    return $name2oid{$oid};
}

sub oid2name {
    my $class = shift;
    my( $oid ) = @_;

    croak( "Class not specifed for oid2name()" ) unless( defined $class );

    return $oid unless( defined $apiVersion && $apiVersion > 0 );

    return $class->_oid2name( @_ );
}

# Should not be exported, as overloading may break ASN lookups

sub _oid2name {
    my $class = shift;
    my( $oid ) = @_;

    return unless($oid);

    if( exists $oids{$oid} ) {
	$oid = $oids{$oid};
    }elsif( exists $oid2extkeyusage{$oid} ) {
	$oid = $oid2extkeyusage{$oid};
    }
    return $oid;
}

# registerOID( $oid ) => true if $oid is registered, false if not
# registerOID( $oid, $longname ) => Register an OID with its name
# registerOID( $oid, $longname, $shortname ) => Register an OID with an abbreviation for RDNs.
# registerOID( $oid, undef, $shortname ) => Register an abbreviation for RDNs for an existing OID

sub registerOID {
    my( $class, $oid, $longname, $shortname ) = @_;

    croak( "Class not specifed for registerOID()" ) unless( defined $class );

    unless( defined $apiVersion ) {
	carp( "${class}::setAPIversion MUST be called before registerOID().  Defaulting to legacy mode" );
	$class->setAPIversion(0);
    }

    return exists $oids{$oid} || exists $oid2extkeyusage{$oid} if( @_ == 2 && defined $oid );

    croak( "Not enough arguments" )              unless( @_ >= 3 && defined $oid && ( defined $longname || defined $shortname ) );
    croak( "Invalid OID $oid" )                  unless( defined $oid && $oid =~ /^\d+(?:\.\d+)*$/ );

    if( defined $longname ) {
        croak( "$oid already registered" )       if( exists $oids{$oid} || exists $oid2extkeyusage{$oid} );
        croak( "$longname already registered" )  if( grep /^$longname$/, values %oids );
    } else {
        croak( "$oid not registered" )           unless( exists $oids{$oid} || exists $oid2extkeyusage{$oid} );
    }
    croak( "$shortname already registered" )     if( defined $shortname && grep /^\U$shortname\E$/,
						                                          values %shortnames );

    if( defined $longname ) {
        $oids{$oid} = $longname;
        $name2oid{$longname} = $oid;
    } else {
        $longname = $class->_oid2name( $oid );
    }
    $shortnames{$longname} = uc $shortname       if( defined $shortname );
    return 1;
}

sub new {
    my $class = shift;

    undef $error;

    $class = ref $class if( defined $class && ref $class && $class->isa( __PACKAGE__ ) );

    unless( defined $apiVersion ) {
	carp( "${class}::setAPIversion MUST be called before new().  Defaulting to legacy mode" );
	$class->setAPIversion(0);
    }

    my( $void, $die ) = ( !defined wantarray, 0 );
    my $self = eval {
        die( "Insufficient arguments for new\n" ) unless( defined $class && @_ >= 1 );
        die( "Value of Crypt::PKCS10->new ignored\n" ) if( $void );
	return $class->_new( \$die, @_ );
    }; if( $@ ) {
	$error = $@;
        if( !$apiVersion || $die || !defined wantarray ) {
            1 while( chomp $@ );
            croak( $@ );
        }
	return;
    }

    return $self;
}

sub error {
    my $class = shift;

    croak( "Class not specifed for error()" ) unless( defined $class );

    if( ref $class && $class->isa( __PACKAGE__ ) ) {
        return $class->{_error};
    }
    return $error;
}

my $pemre = qr/(?ms:^\r?-----BEGIN\s(?:NEW\s)?CERTIFICATE\sREQUEST-----\s*\r?\n\s*(.*?)\s*^\r?-----END\s(?:NEW\s)?CERTIFICATE\sREQUEST-----\r?$)/;

sub _new {
    my( $class, $die, $der ) = splice( @_, 0, 3 );

    my %options = (
                   acceptPEM       => 1,
                   PEMonly         => 0,
                   escapeStrings   => 1,
                   readFile        => 0,
                   ignoreNonBase64 => 0,
                   verifySignature => ($apiVersion >= 1),
                   dieOnError      => 0,
                  );

    %options = ( %options, %{ shift @_ } ) if( @_ >= 1 && ref( $_[0] ) eq 'HASH' );

    die( "Every option to new() must have a value\n" ) unless( @_ % 2 == 0 );

    %options = ( %options, @_ ) if( @_ );

    my $self = { _apiVersion => $apiVersion };

    my $keys = join( '|', qw/escapeStrings acceptPEM PEMonly binaryMode readFile verifySignature ignoreNonBase64 warnings dieOnError/ );

    $self->{"_$_"} = delete $options{$_} foreach (grep { /^(?:$keys)$/ } keys %options);

    $$die = $self->{_dieOnError} &&= $apiVersion >= 1;

    die( "\$csr argument to new() is not defined\n" ) unless( defined $der );

    if( keys %options ) {
	die( "Invalid option(s) specified: " . join( ', ', sort keys %options ) . "\n" );
    }

    $self->{_binaryMode} = !$self->{_acceptPEM} unless( exists $self->{_binaryMode} );

    my $parser;

    # malformed requests can produce various warnings; don't proceed in that case.

    local $SIG{__WARN__} = sub { my $msg = $_[0]; $msg =~ s/\A(.*?) at .*\Z/$1/s; 1 while( chomp $msg ); die "$msg\n" };

    if( $self->{_readFile} ) {
        open( my $fh, '<', $der ) or die( "Failed to open $der: $!\n" );
        $der = $fh;
    }

    if( Scalar::Util::openhandle( $der ) ) {
	local $/;

	binmode $der if( $self->{_binaryMode} );

	$der = <$der>;          # Note: this closes files opened by readFile
	die( "Failed to read request: $!\n" ) unless( defined $der );
    }

    my $isPEM;

    if( $self->{_PEMonly} ) {
        if( $der =~ $pemre ) {
            $der = $1;
            $isPEM = 1;
        } else {
            die( "No certificate request found\n" );
        }
    } elsif( $self->{_acceptPEM} && $der =~ $pemre ) {
        $der = $1;
        $isPEM = 1;
    }
    if( $isPEM ) {
	# Some versions of MIME::Base64 check the input.  Some don't.  Those that do
	# seem to obey -w, but not 'use warnings'.  So we'll check here.

	$der =~ s/\s+//g; # Delete whitespace, which is legal but meaningless
        $der =~ tr~A-Za-z0-9+=/~~cd if( $self->{_ignoreNonBase64} );

	unless( $der =~ m{\A[A-Za-z0-9+/]+={0,2}\z} && ( length( $der ) % 4 == 0 ) ) {
	    warn( "Invalid base64 encoding\n" ); # Invalid character or length
	}
        $der = decode_base64( $der );
    }

    # some requests may contain information outside of the regular ASN.1 structure.
    # This padding must be removed.

    $der = eval { # Catch out of range errors caused by bad DER & report as format errors.
        # SEQUENCE <len> -- CertificationRequest

        my( $tlen, undef, $tag ) = asn_decode_tag2( $der );
        die( "SEQUENCE not present\n" ) unless( $tlen && $tag == ASN_SEQUENCE );

        my( $llen, $len ) = asn_decode_length( substr( $der, $tlen ) );
        die( "Invalid SEQUENCE length\n" ) unless( $llen && $len );

        $len += $tlen + $llen;
        $tlen = length $der;
        die( "DER too short to contain request\n" ) if( $tlen < $len );

        if( $tlen != $len && $self->{_warnings} ) { # Debugging
            local $SIG{__WARN__};
            carp( sprintf( "DER length of %u contains %u bytes of padding",
                           $tlen, $tlen - $len ) );
        }
        return substr( $der, 0, $len );
    }; if( $@ ) {
        1 while( chomp $@ );
        die( "Invalid format for request: $@\n" );
    }

    $self->{_der} = $der;

    bless( $self, $class );

    $self->{_bmpenc} = Encode::find_encoding('UCS2-BE');

    my $asn = Convert::ASN1->new;
    $self->{_asn} = $asn;
    $asn->prepare($schema) or die( "Internal error in " . __PACKAGE__ . ": " . $asn->error );

    $asn->registertype( 'qualifier', '1.3.6.1.5.5.7.2.1', $self->_init('CPSuri') );
    $asn->registertype( 'qualifier', '1.3.6.1.5.5.7.2.2', $self->_init('UserNotice') );

    $parser = $self->_init( 'CertificationRequest' );

    my $top =
	$parser->decode( $der ) or
	  confess( "decode: " . $parser->error .
		   "Cannot handle input or missing ASN.1 definitions" );

    $self->{certificationRequestInfo}{subject_raw}
        = $top->{certificationRequestInfo}{subject};

    $self->{certificationRequestInfo}{subject}
        = $self->_convert_rdn( $top->{certificationRequestInfo}{subject} );

    $self->{certificationRequestInfo}{version}
        = $top->{certificationRequestInfo}{version};

    $self->{certificationRequestInfo}{attributes} = $self->_convert_attributes(
        $top->{certificationRequestInfo}{attributes} );

    $self->{_pubkey} = "-----BEGIN PUBLIC KEY-----\n" .
      _encode_PEM( $self->_init('SubjectPublicKeyInfo')->
                   encode( $top->{certificationRequestInfo}{subjectPKInfo} ) ) .
                     "-----END PUBLIC KEY-----\n";

    $self->{certificationRequestInfo}{subjectPKInfo} = $self->_convert_pkinfo(
        $top->{certificationRequestInfo}{subjectPKInfo} );

    $self->{signature} = $top->{signature};

    $self->{signatureAlgorithm}
        = $self->_convert_signatureAlgorithm( $top->{signatureAlgorithm} );

    # parse parameters for RSA PSS
    if ($self->{signatureAlgorithm}{algorithm} eq 'rsassaPss') {
        my $params = $self->_init('rsassaPssParam')->decode(
            $self->{signatureAlgorithm}{parameters});
        $self->{signatureAlgorithm}{parameters} = {
             'saltLength' => ($params->{saltLength} || 32),
             'digestAlgorithm' => $self->_oid2name($params->{digestAlgorithm}{algorithm}),
        };
    }

    # Extract bundle of bits that is signed
    # The DER is SEQUENCE -- CertificationRequest
    #              SEQUENCE -- CertificationRequestInfo [SIGNED]

    my( $CRtaglen, $CRtag, $CRllen, $CRlen );
    ($CRtaglen, undef, $CRtag) = asn_decode_tag2( $der );
    die( "Invalid CSR format: missing SEQUENCE 1\n" ) unless( $CRtag == ASN_SEQUENCE );
    ($CRllen, $CRlen) = asn_decode_length( substr( $der, $CRtaglen ) );

    my( $CItaglen, $CItag, $CIllen, $CIlen );
    ($CItaglen, undef, $CItag) = asn_decode_tag2( substr( $der, $CRtaglen + $CRllen ) );
    die( "Invalid CSR format: missing SEQUENCE 2\n" ) unless( $CItag == ASN_SEQUENCE );
    ($CIllen, $CIlen) = asn_decode_length( substr( $der, $CRtaglen + $CRllen + $CItaglen ) );

    $self->{_signed} = substr( $der, $CRtaglen +  $CRllen, $CItaglen + $CIllen + $CIlen );

    die( $error ) if( $self->{_verifySignature} && !$self->checkSignature );

    return $self;
}

# Convert::ASN1 returns BMPStrings as 16-bit fixed-width characters, e.g. UCS2-BE

sub _bmpstring {
    my $self = shift;

    my $enc = $self->{_bmpenc};

    $_ = $enc->decode( $_ ) foreach (@_);

    return;
}

# Find the obvious BMPStrings in a value and convert them
# This doesn't catch direct values, but does find them in hashes
# (generally as a result of a CHOICE)
#
# Convert iPAddresses as well

sub _scanvalue {
    my $self = shift;

    my( $value ) = @_;

    return unless( ref $value );
    if( ref $value eq 'ARRAY' ) {
	foreach (@$value) {
	    $self->_scanvalue( $_ );
	}
	return;
    }
    if( ref $value eq 'HASH' ) {
	foreach my $k (keys %$value) {
	    if( $k eq 'bmpString' ) {
		$self->_bmpstring( $value->{bmpString} );
		next;
	    }
	    if( $k eq 'iPAddress' ) {
		use bytes;
		my $addr = $value->{iPAddress};
		if( length $addr == 4 ) {
		    $value->{iPAddress} = sprintf( '%vd', $addr );
		} else {
		    $addr = sprintf( '%*v02X', ':', $addr );
		    $addr =~ s/([[:xdigit:]]{2}):([[:xdigit:]]{2})/$1$2/g;
		    $value->{iPAddress} = $addr;
		}
		next;
	    }
	    $self->_scanvalue( $value->{$k} );
	}
	return;
    }
    return;
}

sub _convert_signatureAlgorithm {
    my $self = shift;

    my $signatureAlgorithm = shift;
    $signatureAlgorithm->{algorithm}
        = $oids{$signatureAlgorithm->{algorithm}}
	  if( defined $signatureAlgorithm->{algorithm}
	    && exists $oids{$signatureAlgorithm->{algorithm}} );

    return $signatureAlgorithm;
}

sub _convert_pkinfo {
    my $self = shift;

    my $pkinfo = shift;

    $pkinfo->{algorithm}{algorithm}
        = $oids{$pkinfo->{algorithm}{algorithm}}
	  if( defined $pkinfo->{algorithm}{algorithm}
	    && exists $oids{$pkinfo->{algorithm}{algorithm}} );
    return $pkinfo;
}

# OIDs requiring some sort of special handling
#
# Called with decoded value, returns updated value.
# Key is ASN macro name

my %special;
%special =
(
 EnhancedKeyUsage => sub {
     my $self = shift;
     my( $value, $id ) = @_;

     foreach (@{$value}) {
	 $_ = $oid2extkeyusage{$_} if(defined $oid2extkeyusage{$_});
     }
     return $value;
 },
 KeyUsage => sub {
     my $self = shift;
     my( $value, $id ) = @_;

     my $bit =  unpack('C*', @{$value}[0]); #get the decimal representation
     my $length = int(log($bit) / log(2) + 1); #get its bit length
     my @usages = reverse( $id eq 'KeyUsage'? # Following are in order from bit 0 upwards
			   qw(digitalSignature nonRepudiation keyEncipherment dataEncipherment
                              keyAgreement keyCertSign cRLSign encipherOnly decipherOnly) :
			   qw(client server email objsign reserved sslCA emailCA objCA) );
     my $shift = ($#usages + 1) - $length; # computes the unused area in @usages

     @usages = @usages[ grep { $bit & (1 << $_ - $shift) } 0 .. $#usages ]; #transfer bitmap to barewords

     return [ @usages ] if( $self->{_apiVersion} >= 1 );

     return join( ', ', @usages );
 },
 netscapeCertType => sub {
     goto &{$special{KeyUsage}};
 },
 SubjectKeyIdentifier => sub {
     my $self = shift;
     my( $value, $id ) = @_;

     return unpack( "H*", $value );
 },
 ApplicationCertPolicies => sub {
     goto &{$special{certificatePolicies}} if( $_[0]->{_apiVersion} > 0 );

     my $self = shift;
     my( $value, $id ) = @_;

     foreach my $entry (@{$value}) {
	 $entry->{policyIdentifier} = $self->_oid2name( $entry->{policyIdentifier} );
     }

     return $value;
 },
 certificateTemplate => sub {
     my $self = shift;
     my( $value, $id ) = @_;

     $value->{templateID} = $self->_oid2name( $value->{templateID} ) if( $self->{_apiVersion} > 0 );
     return $value;
 },
 EnrollmentCSP => sub {
     my $self = shift;
     my( $value, $id ) = @_;

     $self->_bmpstring( $value->{Name} );

     return $value;
 },
 ENROLLMENT_CSP_PROVIDER => sub {
     my $self = shift;
     my( $value, $id ) = @_;

     $self->_bmpstring( $value->{cspName} );

     return $value;
 },
 certificatePolicies => sub {
     my $self = shift;
     my( $value, $id ) = @_;

     foreach my $policy (@$value) {
	 $policy->{policyIdentifier} = $self->_oid2name( $policy->{policyIdentifier} );
	 if( exists $policy->{policyQualifier} ) {
	     foreach my $qualifier (@{$policy->{policyQualifier}}) {
		 $qualifier->{policyQualifierId} = $self->_oid2name( $qualifier->{policyQualifierId} );
		 my $qv = $qualifier->{qualifier};
		 if( ref $qv eq 'HASH' ) {
		     foreach my $qt (keys %$qv) {
			 if( $qt eq 'explicitText' ) {
			     $qv->{$qt} = (values %{$qv->{$qt}})[0];
			 } elsif( $qt eq 'noticeRef' ) {
			     my $userNotice = $qv->{$qt};
			     $userNotice->{organization} = (values %{$userNotice->{organization}})[0];
			 }
		     }
		     $qv->{userNotice} = delete $qv->{noticeRef}
		       if( exists $qv->{noticeRef} );
		 }
	     }
	 }
     }
     return $value;
 },
 CERT_EXTENSIONS => sub {
     my $self = shift;
     my( $value, $id, $entry ) = @_;

     return $self->_convert_extensionRequest( [ $value ] ) if( $self->{_apiVersion} > 0 ); # Untested
 },
 BasicConstraints => sub {
     my $self = shift;
     my( $value, $id, $entry ) = @_;

     my $r = {
	      CA => $value->{cA}? 'TRUE' : 'FALSE',
	     };
     my $string = "CA:$r->{CA}";

     if( exists $value->{pathLenConstraint} ) {
	 $r->{pathlen} = $value->{pathLenConstraint};
	 $string .= sprintf( ',pathlen:%u', $value->{pathLenConstraint} );
     }
     $entry->{_FMT} = [ $r, $string ]; # [ Raw, formatted ]
     return $value;
 },
 unstructuredName => sub {
     my $self = shift;
     my( $value, $id ) = @_;

     return $self->_hash2string( $value );
 },
 challengePassword => sub {
     my $self = shift;
     my( $value, $id ) = @_;

     return $self->_hash2string( $value );
 },
); # %special

sub _convert_attributes {
    my $self = shift;
    my( $typeandvalues ) = @_;

    foreach my $entry ( @{$typeandvalues} ) {
    my $oid = $entry->{type};
    my $name = $oids{$oid};
    $name = $variantNames{$name} if( defined $name && exists $variantNames{$name} );

    next unless( defined $name );

    $entry->{type} = $name;

    if ($name eq 'extensionRequest') {
        $entry->{values} = $self->_convert_extensionRequest($entry->{values}[0]);

    } elsif ($name eq 'ENROLLMENT_NAME_VALUE_PAIR') {
        my $parser = $self->_init( $name );
        my @values;
        foreach my $der (@{$entry->{values}}) {
            my $pair = $parser->decode( $der ) or
                confess( "Looks like damaged input parsing attribute $name" );
                $self->_bmpstring( $pair->{name}, $pair->{value} );
            push @values, $pair;
        };
        $entry->{values} = \@values;

    } else {
        my $parser = $self->_init( $name, 1 ) or next; # Skip unknown attributes

        if($entry->{values}[1]) {
            confess( "Incomplete parsing of attribute type: $name" );
        }
        my $value = $entry->{values} = $parser->decode( $entry->{values}[0] ) or
        confess( "Looks like damaged input parsing attribute $name" );

        if( exists $special{$name} ) {
        my $action = $special{$name};
        $entry->{values} = $action->( $self, $value, $name, $entry );
        }
    }
    }
    return $typeandvalues;
}

sub _convert_extensionRequest {
    my $self = shift;
    my( $extensionRequest ) = @_;

    my $parser = $self->_init('extensionRequest');
    my $decoded = $parser->decode($extensionRequest) or return [];

    foreach my $entry (@{$decoded}) {
	my $name = $oids{ $entry->{extnID} };
	$name = $variantNames{$name} if( defined $name && exists $variantNames{$name} );
        if (defined $name) {
	    my $asnName = $name;
	    $asnName =~ tr/ //d;
            my $parser = $self->_init($asnName, 1);
            if(!$parser) {
                $entry = undef;
                next;
            }
            $entry->{extnID} = $name;
            my $dec = $parser->decode($entry->{extnValue}) or
	      confess( $parser->error . ".. looks like damaged input parsing extension $asnName" );

	    $self->_scanvalue( $dec );

	    if( exists $special{$asnName} ) {
		my $action = $special{$asnName};
		$dec = $action->( $self, $dec, $asnName, $entry );
	    }
	    $entry->{extnValue} = $dec;
        }
    }
    @{$decoded} = grep { defined } @{$decoded};
    return $decoded;
}

sub _convert_rdn {
    my $self = shift;
    my $typeandvalue = shift;
    my %hash = ( _subject => [], );
    foreach my $entry ( @$typeandvalue ) {
	foreach my $item (@$entry) {
	    my $oid = $item->{type};
	    my $name = (exists $variantNames{$oid})? $variantNames{$oid}[1]: $oids{ $oid };
	    if( defined $name ) {
		push @{$hash{$name}}, sort values %{$item->{value}};
		push @{$hash{_subject}}, $name, [ sort values %{$item->{value}} ];
		my @names = (exists $variantNames{$oid})? @{$variantNames{$oid}} : ( $name );
		foreach my $name ( @names ) {
		    unless( $self->can( $name ) ) {
			no strict 'refs'; ## no critic
			*$name =  sub {
			    my $self = shift;
			    return @{ $self->{certificationRequestInfo}{subject}{$name} } if( wantarray );
			    return $self->{certificationRequestInfo}{subject}{$name}[0] || '';
			}
		    }
		}
	    }
	}
    }

    return \%hash;
}

sub _init {
    my $self = shift;
    my( $node, $optional ) = @_;

    my $parsed = $self->{_asn}->find($node);

    unless( defined $parsed || $optional ) {
	croak( "Missing node $node in ASN.1" );
    }
    return $parsed;
}

###########################################################################
# interface methods

sub csrRequest {
    my $self = shift;
    my $format = shift;

    return( "-----BEGIN CERTIFICATE REQUEST-----\n" .
	    _encode_PEM( $self->{_der} ) .
	    "-----END CERTIFICATE REQUEST-----\n" ) if( $format );

    return $self->{_der};
}

# Common subject components documented to be always present:

foreach my $component (qw/commonName organizationalUnitName organizationName
                          emailAddress stateOrProvinceName countryName domainComponent/ ) {
    no strict 'refs'; ## no critic

    unless( defined &$component ) {
	*$component = sub {
	    my $self = shift;
	    return @{ $self->{certificationRequestInfo}{subject}{$component} || [] } if( wantarray );
	    return $self->{certificationRequestInfo}{subject}{$component}[0] || '';
	}
    }
}

# Complete subject

sub subject {
    my $self = shift;
    my $long = shift;

    return @{ $self->{certificationRequestInfo}{subject}{_subject} } if( wantarray );

    my @subject = @{ $self->{certificationRequestInfo}{subject}{_subject} };

    my $subj = '';
    while( @subject ) {
	my( $name, $value ) = splice( @subject, 0, 2 );
	$name = $shortnames{$name} if( !$long && exists $shortnames{$name} );
	$subj .= "/$name=" . join( ',', @$value );
    }

    return $subj;
}


sub subjectRaw {

    my $self = shift;
    my @subject;
    foreach my $rdn (@{$self->{certificationRequestInfo}{subject_raw}}) {
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


sub subjectAltName {
    my $self = shift;
    my( $type ) = @_;

    my $san = $self->extensionValue( 'subjectAltName' );
    unless( defined $san ) {
	return () if( wantarray );
	return undef;  ## no critic
    }

    if( !defined $type ) {
	if( wantarray ) {
	    my %comps;
	    $comps{$_} = 1 foreach (map { keys %$_ } @$san);
	    return sort keys %comps; ## no critic
	}
	my @string;
	foreach my $comp (@$san) {
	    push @string, join( '+', map { "$_:$comp->{$_}" } sort keys %$comp );
	}
	return join( ',', @string );
    }

    my $result = [ map { $_->{$type} } grep { exists $_->{$type} } @$san ];

    return @$result if( wantarray );
    return $result->[0];
}

sub version {
    my $self = shift;
    my $v = $self->{certificationRequestInfo}{version};
    return sprintf( "v%u", $v+1 );
}

sub pkAlgorithm {
    my $self = shift;
    return $self->{certificationRequestInfo}{subjectPKInfo}{algorithm}{algorithm};
}

sub subjectPublicKey {
    my $self = shift;
    my $format = shift;

    return $self->{_pubkey} if( $format );
    return unpack('H*', $self->{certificationRequestInfo}{subjectPKInfo}{subjectPublicKey}[0]);
}

sub subjectPublicKeyParams {
    my $self = shift;
    my $detail = shift;

    croak( "Requires API version 1" ) unless( $self->{_apiVersion} >= 1 );

    undef $error;
    delete $self->{_error};

    my $rv = {};
    my $at = $self->pkAlgorithm;
    $at = 'undef' unless( defined $at );

    if( $at eq 'rsaEncryption' ) {
        $rv->{keytype} = 'RSA';
        my $par = $self->_init( 'rsaKey' );
        my $rsa = $par->decode( $self->{certificationRequestInfo}{subjectPKInfo}{subjectPublicKey}[0] );
        $rv->{keylen} = 4 * ( length( $rsa->{modulus}->as_hex ) -2 ); # 2 == length( '0x' )
        $rv->{modulus} = substr( $rsa->{modulus}->as_hex, 2 );
        $rv->{publicExponent} = ( ref( $rsa->{publicExponent} )?
                                  $rsa->{publicExponent}->as_hex :
                                  sprintf( '%x', $rsa->{publicExponent} ) );
    } elsif( $at eq 'ecPublicKey' ) {
        $rv->{keytype} = 'ECC';

        eval { require Crypt::PK::ECC; };
        if( $@ ) {
            $rv->{keytype} = undef;
            $self->{_error} =
              $error = "ECC public key requires Crypt::PK::ECC\n";
            croak( $error ) if( $self->{_dieOnError} );
            return $rv;
        }
        my $key = $self->subjectPublicKey(1);
        $key = Crypt::PK::ECC->new( \$key )->key2hash;
        $rv->{keylen} = $key->{curve_bits};
        $rv->{pub_x}  = $key->{pub_x};
        $rv->{pub_y}  = $key->{pub_y};
        $rv->{detail} = { %$key } if( $detail );

        my $par = $self->_init( 'eccName' );
        $rv->{curve} = $par->decode( $self->{certificationRequestInfo}{subjectPKInfo}{algorithm}{parameters} );
        $rv->{curve} = $self->_oid2name( $rv->{curve} ) if ($rv->{curve});
    } elsif( $at eq 'dsa' ) {
        $rv->{keytype} = 'DSA';
        my $par = $self->_init( 'dsaKey' );
        my $dsa = $par->decode( $self->{certificationRequestInfo}{subjectPKInfo}{subjectPublicKey}[0] );
        $rv->{keylen} = 4 * ( length( $dsa->as_hex ) -2 );
        if( exists $self->{certificationRequestInfo}{subjectPKInfo}{algorithm}{parameters} ) {
            $par = $self->_init('dsaPars');
            $dsa = $par->decode($self->{certificationRequestInfo}{subjectPKInfo}{algorithm}{parameters});
            $rv->{G} = substr( $dsa->{G}->as_hex, 2 );
            $rv->{P} = substr( $dsa->{P}->as_hex, 2 );
            $rv->{Q} = substr( $dsa->{Q}->as_hex, 2 );
        }
    } else {
        $rv->{keytype} = undef;
        $self->{_error} =
          $error = "Unrecognized public key type $at\n";
        croak( $error ) if( $self->{_dieOnError} );
    }
    return $rv;
}

sub signatureAlgorithm {
    my $self = shift;
    return $self->{signatureAlgorithm}{algorithm};
}

sub signatureParams {
    my $self = shift;

    return unless ( exists $self->{signatureAlgorithm}{parameters} );

    # For RSA PSS the parameters have been parsed to a hash already
    if (ref $self->{signatureAlgorithm}{parameters} eq 'HASH') {
        return $self->{signatureAlgorithm}{parameters};
    }

    my( $tlen, undef, $tag ) = asn_decode_tag2( $self->{signatureAlgorithm}{parameters} );
    if( $tlen != 0 && $tag != ASN_NULL ) {
        return $self->{signatureAlgorithm}{parameters}
    }
    # Known algorithm's parameters MAY return a hash of decoded fields.
    # For now, leaving that to the caller...

    return;
}

sub signature {
    my $self = shift;
    my $format = shift;

    if( defined $format && $format == 2 ) { # Per keytype decoding
        if( $self->pkAlgorithm eq 'ecPublicKey' ) { # ECDSA
            my $par = $self->_init( 'ecdsaSigValue' );
            return $par->decode( $self->{signature}[0] );
        }
        return;                             # Unknown
    }
    return $self->{signature}[0] if( $format );

    return unpack('H*', $self->{signature}[0]);
}

sub certificationRequest {
    my $self = shift;

    return $self->{_signed};
}

sub _attributes {
    my $self = shift;

    my $attributes = $self->{certificationRequestInfo}{attributes};
    return unless( defined $attributes );

    return { map { $_->{type} => $_->{values} } @$attributes };
}

sub attributes {
    my $self = shift;
    my( $name ) = @_;

    if( $self->{_apiVersion} < 1 ) {
	my $attributes = $self->{certificationRequestInfo}{attributes};
	return () unless( defined $attributes );

	my %hash = map { $_->{type} => $_->{values} }
	  @{$attributes};
	return %hash;
    }

    my $attributes = $self->_attributes;
    unless( defined $attributes ) {
	return () if( wantarray );
	return undef;  ## no critic
    }

    unless( defined $name ) {
	return grep { $_  ne 'extensionRequest' } sort keys %$attributes;
    }

    $name = $self->_oid2name( $name );

    if( $name eq 'extensionRequest' ) { # Meaningless, and extensions/extensionValue handle
	return () if( wantarray );
	return undef; ## no critic
    }

    # There can only be one matching the name.
    # If the match becomes wider, sort the keys.


    my @attrs = grep { $_ eq $name } keys %$attributes;
    unless( @attrs ) {
	return () if( wantarray );
	return undef; ## no critic
    }

    my @values;
    foreach my $attr (@attrs) {
	my $values = $attributes->{$attr};
	$values = [ $values ] unless( ref $values eq 'ARRAY' );
	foreach my $value (@$values)  {
	    my $value = $self->_hash2string( $value );
	    push @values, (wantarray? $value : $self->_value2strings( $value ));
	}
    }
    return @values if( wantarray );

    if( @values == 1 ) {
	$values[0] =~ s/^\((.*)\)$/$1/;
	return $values[0];
    }
    return join( ',', @values );
}

sub certificateTemplate {
    my $self = shift;

    return $self->extensionValue( 'certificateTemplate', @_ );
}

# If a hash contains one string (e.g. a CHOICE containing type=>value), return the string.
# If the hash is nested, try recursing.
# If the string can't be identified (clutter in the hash), return the hash
# Some clutter can be filtered by specifying $exclude (a regexp)

sub _hash2string {
    my $self = shift;
    my( $hash, $exclude ) = @_;

    return $hash unless( ref $hash eq 'HASH' );

    my @keys = keys %$hash;

    @keys = grep { $_ !~ /$exclude/ } @keys if( defined $exclude );

    return $hash if( @keys != 1 );

    return $self->_hash2string( $hash->{$keys[0]} ) if( ref $hash->{$keys[0]} eq 'HASH' );

    return $hash->{$keys[0]};
}

# Convert a value to a printable string

sub _value2strings {
    my $self = shift;
    my( $value ) = @_;

    my @strings;
    if( ref $value eq 'ARRAY' ) {
	foreach my $value (@$value) {
	    push @strings, $self->_value2strings( $value );
	}
	return '(' . join( ',', @strings ) . ')' if( @strings > 1 );
	return join( ',', @strings );
    }
    if( ref $value eq 'HASH' ) {
	foreach my $k (sort keys %$value) {
	    push @strings, "$k=" . $self->_value2strings( $value->{$k} );
	}
	return '(' . join( ',', @strings ) . ')' if( @strings > 1 );
	return join( ',', @strings );
    }

    return $value if( $value =~ /^\d+$/ );

    # OpenSSL and Perl-compatible string syntax

    $value =~ s/(["\\\$])/\\$1/g if( $self->{_escapeStrings} );

    return $value if( $value =~ m{\A[\w!\@$%^&*_=+\[\]\{\}:;|<>./?"'-]+\z} ); # Barewords

    return '"' . $value . '"'; # Must quote: whitespace, non-printable, comma, (), \, null string
}

sub extensions {
    my $self = shift;

    my $attributes = $self->_attributes;
    return () unless( defined $attributes && exists $attributes->{extensionRequest} );

    my @present =  map { $_->{extnID} } @{$attributes->{extensionRequest}};
    if( $self->{_apiVersion} >= 1 ) {
	foreach my $ext (@present) {
	    $ext = $variantNames{'$' . $ext} if( exists $variantNames{'$' . $ext} );
	}
    }
    return @present;
}

sub extensionValue {
    my $self = shift;
    my( $extensionName, $format ) = @_;

    my $attributes = $self->_attributes;
    my $value;
    return unless( defined $attributes && exists $attributes->{extensionRequest} );

    $extensionName = $self->_oid2name( $extensionName );

    $extensionName = $variantNames{$extensionName} if( exists $variantNames{$extensionName} );

    foreach my $entry (@{$attributes->{extensionRequest}}) {
        if ($entry->{extnID} eq $extensionName) {
            $value = $entry->{extnValue};
	    if( $self->{_apiVersion} == 0 ) {
		while (ref $value eq 'HASH') {
		    my @keys = sort keys %{$value};
		    $value = $value->{ shift @keys } ;
		}
	    } else {
		if( $entry->{_FMT} ) { # Special formatting
		    $value = $entry->{_FMT}[$format? 1:0];
		} else {
		    $value = $self->_hash2string( $value, '(?i:^(?:critical|.*id)$)' );
		    $value = $self->_value2strings( $value ) if( $format );
		}
	    }
	    last;
        }
    }
    $value =~ s/^\((.*)\)$/$1/ if( $format );

    return $value;
}

sub extensionPresent {
    my $self = shift;
    my( $extensionName ) = @_;

    my $attributes = $self->_attributes;
    return unless( defined $attributes && exists $attributes->{extensionRequest} );

    $extensionName = $self->_oid2name( $extensionName );

    $extensionName = $variantNames{$extensionName} if( exists $variantNames{$extensionName} );

    foreach my $entry (@{$attributes->{extensionRequest}}) {
        if ($entry->{extnID} eq $extensionName) {
	    return 2 if ($entry->{critical});
	    return 1;
        }
    }
    return;
}

sub checkSignature {
    my $self = shift;

    undef $error;
    delete $self->{_error};

    my $ok = eval {
        die( "checkSignature requires API version 1\n" ) unless( $self->{_apiVersion} >= 1 );

        my $key = $self->subjectPublicKey(1); # Key as PEM
        my $sig = $self->signature(1);        # Signature as DER
        my $alg = $self->signatureAlgorithm;  # Algorithm name

        # Determine the signature hash type from the algorithm name

        my @params = ( $sig, $self->certificationRequest );
        if( $alg =~ /sha-?(\d+)/i ) {
            push @params, "SHA$1";

        } elsif( $alg =~ /md-?(\d)/i ) {
            push @params, "MD$1";

        } elsif ( $alg eq 'rsassaPss' ) {

            my $sigParam = $self->signatureParams;
            push @params, uc($sigParam->{digestAlgorithm});
            push @params, 'pss';
            push @params, $sigParam->{saltLength};

        } else {

            die( "Unknown hash in signature algorithm $alg\n" );
        }

        my $keyp = $self->subjectPublicKeyParams;

        die( "Unknown public key type\n" ) unless( defined $keyp->{keytype} );

        # Verify signature using the correct module and hash type.

        if( $keyp->{keytype} eq 'RSA' ) {

            eval { require Crypt::PK::RSA; };
            die( "Unable to load Crypt::PK::RSA\n" ) if( $@ );

            $key = Crypt::PK::RSA->new( \$key );

            # if we have NOT pss padding we need to add v1.5 padding
            push @params, 'v1.5' if (@params == 3);
            return $key->verify_message( @params );

        }

        if( $keyp->{keytype} eq 'DSA' ) {

            eval { require Crypt::PK::DSA; };
            die( "Unable to load Crypt::PK::DSA\n" ) if( $@ );

            $key = Crypt::PK::DSA->new( \$key );
            return $key->verify_message( @params );
        }

        if( $keyp->{keytype} eq 'ECC' ) {
            eval { require Crypt::PK::ECC; };
            die( "Unable to load Crypt::PK::ECC\n" ) if( $@ );

            $key = Crypt::PK::ECC->new( \$key );
            return $key->verify_message( @params );
        }

        die( "Unknown key type $keyp->{keytype}\n" );
    };
    if( $@ ) {
        $self->{_error} =
          $error = $@;
        croak( $error ) if( $self->{_dieOnError} );
        return;
    }
    return 1 if( $ok );

    $self->{_error} =
      $error = "Incorrect signature\n";
    croak( $error ) if( $self->{_dieOnError} );

    return 0;
}

sub _wrap {
    my( $to, $text ) = @_;

    my $wid = 76 - $to;

    my $out = substr( $text, 0, $wid, '' );

    while( length $text ) {
	$out .= "\n" . (' ' x $to) . substr( $text, 0, $wid, '' );
    }
    return $out;
}

sub _encode_PEM {
    my $text = encode_base64( $_[0] );
    return $text if( length $text <= 65 );
    $text    =~ tr/\n//d;
    my $out  = '';
    $out    .= substr( $text, 0, 64, '' ) . "\n" while( length $text );
    return   $out;
}

sub as_string {
    my $self = shift;

    local $self->{_escapeStrings} = 0;
    local( $@, $_, $! );

    my $v = $apiVersion;
    ref( $self )->setAPIversion( 1 ) unless( defined $v && $v == 1 );

    my $string = eval {
        $self = ref( $self )->new( $self->{_der}, acceptPEM => 0, verifySignature => 0, escapeStrings => 0 );
        return $error if( !defined $self );

        $self->__stringify;
    };
    my $at = $@;
    ref( $self )->setAPIversion( $v ) unless( defined $v && $v == 1 );

    $string = '' unless( defined $string );
    $string .= $at if( $at );

    return $string;
}

sub __stringify {
    my $self = shift;

    my $max = 0;
    foreach ($self->attributes, $self->extensions,
	     qw/Version Subject Key_algorithm Public_key Signature_algorithm Signature/) {
	$max = length if( length > $max );
    }

    my $string = sprintf( "%-*s: %s\n", $max, 'Version', $self->version ) ;

    $string .= sprintf( "%-*s: %s\n", $max, 'Subject', _wrap( $max+2, scalar $self->subject ) );

    $string .= "\n          --Attributes--\n";

    $string .= "     --None--" unless( $self->attributes );

    foreach ($self->attributes) {
	$string .= sprintf( "%-*s: %s\n", $max, $_, _wrap( $max+2, scalar $self->attributes($_) ) );
    }

    $string .= "\n          --Extensions--\n";

    $string .= "     --None--" unless( $self->extensions );

    foreach ($self->extensions) {
	my $critical = $self->extensionPresent($_) == 2? 'critical,': '';

	$string .= sprintf( "%-*s: %s\n", $max, $_,
			    _wrap( $max+2, $critical . ($_ eq 'subjectAltName'?
							scalar $self->subjectAltName:
							$self->extensionValue($_, 1) ) ) );
    }

    $string .= "\n          --Key and signature--\n";
    $string .= sprintf( "%-*s: %s\n", $max, 'Key algorithm', $self->pkAlgorithm );
    $string .= sprintf( "%-*s: %s\n", $max, 'Public key', _wrap( $max+2, $self->subjectPublicKey ) );
    $string .= $self->subjectPublicKey(1);
    my $kp = $self->subjectPublicKeyParams(1);
    foreach (sort keys %$kp) {
        my $v = $kp->{$_};

        if( !defined $v && !defined( $v = $self->error ) ) {
            $v = 'undef';
        } elsif( ref $v ) {
            next;
        }
        $string .= sprintf( "%-*s: %s\n", $max, $_, _wrap( $max+2, $v ) );
    }
    if( exists $kp->{detail} ) {
        $kp = $kp->{detail};
        $string .= "Key details\n-----------\n";
        foreach (sort keys %$kp) {
            next if( ref $kp->{$_} );
            $string .= sprintf( "%-*s: %s\n", $max, $_, _wrap( $max+2, $kp->{$_} ) );
        }
    }

    $string .= sprintf( "\n%-*s: %s\n", $max, 'Signature algorithm', $self->signatureAlgorithm );
    $string .= sprintf( "%-*s: %s\n", $max, 'Signature', _wrap( $max+2, $self->signature ) );
    my $sp = $self->signature(2);
    if( $sp ) {
        foreach (sort keys %$sp) {
            my $v = $sp->{$_};

            if( ref $v ) {
                if( $v->can('as_hex') ) {
                    $v = substr( $v->as_hex, 2 );
                } else {
                    next;
                }
            }
            $string .= sprintf( "%-*s: %s\n", $max, $_, _wrap( $max+2, $v ) );
        }
    }

    $string .= "\n          --Request--\n" . $self->csrRequest(1);

    return $string;
}

1;

__END__

=encoding utf-8

=pod

=begin :readme

  This file is automatically generated by pod2readme from PKCS10.pm and Changes.

=end :readme

=head1 NAME

Crypt::PKCS10 - parse PKCS #10 certificate requests

=begin :readme

=head1 RELEASE NOTES

Version 1.4 made several API changes.  Most users should have a painless migration.

ALL users must call Crypt::PKCS10->setAPIversion.  If not, a warning will be generated
by the first class method called.  This warning will be made a fatal exception in a
future release.

Other than that requirement, the legacy mode is compatible with previous versions.

C<new> will no longer generate exceptions.  C<undef> is returned on all errors. Use
the error class method to retrieve the reason.

new will accept an open file handle in addition to a request.

Users are encouraged to migrate to the version 1 API.  It is much easier to use,
and does not require the application to navigate internal data structures.

Version 1.7 provides support for DSA and ECC public keys.  By default, it verifies
the signature of CSRs.  It also allows the caller to verify the signature of a CSR.
subjectPublicKeyParams and signatureParams provide additional information.
The readFile option to new() will open() a file containing a CSR by name.
The ignoreNonBase64 option allows PEM to contain extraneous characters.
F<Changes> describes additional improvements.  Details follow.

=head1 INSTALLATION

C<Crypt::PKCS10> supports DSA, RSA and ECC public keys in CSRs.

It depends on C<Crypt::PK::*> (provided by CryptX) for some operations.
All are recommended. Some methods will return errors if
Crypt::PKCS10 is presented with a CSR containing an unsupported public key type.

To install this module type the following:

    perl Makefile.PL
    make
    make test
    make install

=head1 REQUIRES

C<Convert::ASN1>

C<Crypt::PK::DSA>

C<Crypt::PK::RSA>

C<Crypt::PK::ECC>

C<Digest::SHA>

Very old CSRs may require C<DIGEST::MD{5,4,2}>

=end :readme

=head1 SYNOPSIS

    use Crypt::PKCS10;

    Crypt::PKCS10->setAPIversion( 1 );
    my $decoded = Crypt::PKCS10->new( $csr ) or die Crypt::PKCS10->error;

    print $decoded;

    @names = $decoded->extensionValue('subjectAltName' );
    @names = $decoded->subject unless( @names );

    %extensions = map { $_ => $decoded->extensionValue( $_ ) } $decoded->extensions

=head1 DESCRIPTION

C<Crypt::PKCS10> parses PKCS #10 certificate requests (CSRs) and provides accessor methods to extract the data in usable form.

Common object identifiers will be translated to their corresponding names.
Additionally, accessor methods allow extraction of single data fields.
The format of returned data varies by accessor.

The access methods return the value corresponding to their name.  If called in scalar context, they return the first value (or an empty string).  If called in array context, they return all values.

B<true> values should be specified as 1 and B<false> values as 0.  Future API changes may provide different functions when other values are used.

=head1 METHODS

Access methods may exist for subject name components that are not listed here.  To test for these, use code of the form:

  $locality = $decoded->localityName if( $decoded->can('localityName') );

If a name component exists in a CSR, the method will be present.  The converse is not (always) true.

=head2 class method setAPIversion( $version )

Selects the API version (0 or 1) expected.

Must be called before calling any other method.

The API version determines how a CSR is parsed.  Changing the API version after
parsing a CSR will cause accessors to produce unpredictable results.

=over 4

=item Version 0 - B<DEPRECATED>

Some OID names have spaces and descriptions

This is the format used for C<Crypt::PKCS10> version 1.3 and lower.  The attributes method returns legacy data.

Some new API functions are disabled.

=item Version 1

OID names from RFCs - or at least compatible with OpenSSL and ASN.1 notation.  The attributes method conforms to version 1.

=back

If not called, a warning will be generated and the API will default to version 0.

In a future release, the warning will be changed to a fatal exception.

To ease migration, both old and new names are accepted by the API.

Every program should call C<setAPIversion(1)>.

=cut

=head2 class method getAPIversion

Returns the current API version.

Returns C<undef> if setAPIversion has never been called.

=head2 class method new( $csr, %options )

Constructor, creates a new object containing the parsed PKCS #10 certificate request.

C<$csr> may be a scalar containing the request, a file name, or a file handle from which to read it.

If a file name is specified, the C<readFile> option must be specified.

If a file handle is supplied, the caller should specify C<< acceptPEM => 0 >> if the contents are DER.

The request may be PEM or binary DER encoded.  Only one request is processed.

If PEM, other data (such as mail headers) may precede or follow the CSR.

    my $decoded = Crypt::PKCS10->new( $csr ) or die Crypt::PKCS10->error;

Returns C<undef> if there is an I/O error or the request can not be parsed successfully.

Call C<error()> to obtain more detail.

=head3 options

The options are specified as C<< name => value >>.

If the first option is a HASHREF, it is expanded and any remaining options are added.

=over 4

=item acceptPEM

If B<false>, the input must be in DER format.  C<binmode> will be called on a file handle.

If B<true>, the input is checked for a C<CERTIFICATE REQUEST> header.  If not found, the csr
is assumed to be in DER format.

Default is B<true>.

=item PEMonly

If B<true>, the input must be in PEM format.  An error will be returned if the input doesn't contain a C<CERTIFICATE REQUEST> header.
If B<false>, the input is parsed according to C<acceptPEM>.

Default is B<false>.

=item binaryMode

If B<true>, an input file or file handle will be set to binary mode prior to reading.

If B<false>, an input file or file handle's C<binmode> will not be modified.

Defaults to B<false> if B<acceptPEM> is B<true>, otherwise B<true>.

=item dieOnError

If B<true>, any API function that sets an error string will also C<die>.

If B<false>, exceptions are only generated for fatal conditions.

The default is B<false>.  API version 1 only..

=item escapeStrings

If B<true>, strings returned for extension and attribute values are '\'-escaped when formatted.
This is compatible with OpenSSL configuration files.

The special characters are: '\', '$', and '"'

If B<false>, these strings are not '\'-escaped.  This is useful when they are being displayed
to a human.

The default is B<true>.

=item ignoreNonBase64

If B<true>, most invalid base64 characters in PEM data will be ignored.  For example, this will
accept CSRs prefixed with '> ', as e-mail when the PEM is inadvertently quoted.  Note that the
BEGIN and END lines may not be corrupted.

If B<false>, invalid base64 characters in PEM data will cause the CSR to be rejected.

The default is B<false>.

=item readFile

If B<true>, C<$csr> is the name of a file containing the CSR.

If B<false>, C<$csr> contains the CSR or is an open file handle.

The default is B<false>.

=item verifySignature

If B<true>, the CSR's signature is checked.  If verification fails, C<new> will fail.  Requires API version 1.

If B<false>, the CSR's signature is not checked.

The default is B<true> for API version 1 and B<false> for API version 0.

See C<checkSignature> for requirements and limitations.

=back

No exceptions are generated, unless C<dieOnError> is set or C<new()> is called in
void context.

The defaults will accept either PEM or DER from a string or file hande, which will
not be set to binary mode.  Automatic detection of the data format may not be
reliable on file systems that represent text and binary files differently. Set
C<acceptPEM> to B<false> and C<PEMonly> to match the file type on these systems.

The object will stringify to a human-readable representation of the CSR.  This is
useful for debugging and perhaps for displaying a request.  However, the format
is not part of the API and may change.  It should not be parsed by automated tools.

Exception: The public key and extracted request are PEM blocks, which other tools
can extract.

If another object inherits from C<Crypt::PKCS10>, it can extend the representation
by overloading or calling C<as_string>.

=head2 {class} method error

Returns a string describing the last error encountered;

If called as an instance method, last error encountered by the object.

If called as a class method, last error encountered by the class.

Any method can reset the string to B<undef>, so the results are
only valid immediately after a method call.

=head2 class method name2oid( $oid )

Returns the OID corresponding to a name returned by an access method.

Not in API v0;

=head2 csrRequest( $format )

Returns the binary (ASN.1) request (after conversion from PEM and removal of any data beyond the length of the ASN.1 structure.

If $format is B<true>, the request is returned as a PEM CSR.  Otherwise as a binary string.

=head2 certificationRequest

Returns the binary (ASN.1) section of the request that is signed by the requestor.

The caller can verify the signature using B<signatureAlgorithm>, B<certificationRequest> and B<signature(1)>.

=head2 Access methods for the subject's distinguished name

Note that B<subjectAltName> is prefered, and that modern certificate users will ignore the subject if B<subjectAltName> is present.

=head3 subject( $format )

Returns the entire subject of the CSR.

In scalar context, returns the subject as a string in the form C</componentName=value,value>.
  If format is B<true>, long component names are used.  By default, abbreviations are used when they exist.

  e.g. /countryName=AU/organizationalUnitName=Big org/organizationalUnitName=Smaller org
  or     /C=AU/OU=Big org/OU=Smaller org

In array context, returns an array of C<(componentName, [values])> pairs.  Abbreviations are not used.

Note that the order of components in a name is significant.


=head3 subjectRaw

Returns the subjects RDNs as sequence of hashes without OID any mapping applied.

The result is an array ref where each item is a hash:

    [
        {
        'format' => 'ia5String',
        'value' => 'Org',
        'type' => '0.9.2342.19200300.100.1.25'
        },
        {
        'format' => 'utf8String',
        'value' => 'ACME',
        'type' => '2.5.4.10'
        },
        {
        'format' => 'utf8String',
        'type' => '2.5.4.3',
        'value' => 'Foobar'
        }
    ]

If a component contains a SET, the component will become an array on the
second level, too:

    [
        {
        'format' => 'ia5String',
        'value' => 'Org',
        'type' => '0.9.2342.19200300.100.1.25'
        },
        {
        'format' => 'utf8String',
        'value' => 'ACME',
        'type' => '2.5.4.10'
        },
        [
            {
                'format' => 'utf8String',
                'type' => '2.5.4.3',
                'value' => 'Foobar'
            },
            {
                'format' => 'utf8String',
                'type' => '0.9.2342.19200300.100.1.1',
                'value' => 'foobar'
            }
        ]
    ];

=head3 commonName

Returns the common name(s) from the subject.

    my $cn = $decoded->commonName();

=head3 organizationalUnitName

Returns the organizational unit name(s) from the subject

=head3 organizationName

Returns the organization name(s) from the subject.

=head3 emailAddress

Returns the email address from the subject.

=head3 stateOrProvinceName

Returns the state or province name(s) from the subject.

=head3 countryName

Returns the country name(s) from the subject.

=head2 subjectAltName( $type )

Convenience method.

When $type is specified: returns the subject alternate name values of the specified type in list context, or the first value
of the specified type in scalar context.

Returns undefined/empty list if no values of the specified type are present, or if the B<subjectAltName>
extension is not present.

Types can be any of:

   otherName
 * rfc822Name
 * dNSName
   x400Address
   directoryName
   ediPartyName
 * uniformResourceIdentifier
 * iPAddress
 * registeredID

The types marked with '*' are the most common.

If C<$type> is not specified:
 In list context returns the types present in the subjectAlternate name.
 In scalar context, returns the SAN as a string.

=head2 version

Returns the structure version as a string, e.g. "v1" "v2", or "v3"

=head2 pkAlgorithm

Returns the public key algorithm according to its object identifier.

=head2 subjectPublicKey( $format )

If C<$format> is B<true>, the public key will be returned in PEM format.

Otherwise, the public key will be returned in its hexadecimal representation

=head2 subjectPublicKeyParams

Returns a hash describing the public key.  The contents vary depending on
the public key type.

=head3 Standard items:

C<keytype> - ECC, RSA, DSA or C<undef>

C<keytype> will be C<undef> if the key type is not supported.  In
this case, C<error()> returns a diagnostic message.

C<keylen> - Approximate length of the key in bits.

Other items include:

For RSA, C<modulus> and C<publicExponent>.

For DSA, C<G, P and Q>.

For ECC, C<curve>, C<pub_x> and C<pub_y>.  C<curve> is an OID name.

=head3 Additional detail

C<subjectPublicKeyParams(1)> returns the standard items, and may
also return C<detail>, which is a hashref.

For ECC, the C<detail> hash includes the curve definition constants.

=head2 signatureAlgorithm

Returns the signature algorithm according to its object identifier.

=head2 signatureParams

Returns the parameters associated with the B<signatureAlgorithm> as binary.
Returns B<undef> if none, or if B<NULL>.

Note: In the future, some B<signatureAlgorithm>s may return a hashref of decoded fields.

Callers are advised to check for a ref before decoding...

=head2 signature( $format )

The CSR's signature is returned.

If C<$format> is B<1>, in binary.

If C<$format> is B<2>, decoded as an ECDSA signature - returns hashref to C<r> and C<s>.

Otherwise, in its hexadecimal representation.

=head2 attributes( $name )

A request may contain a set of attributes. The attributes are OIDs with values.
The most common is a list of requested extensions, but other OIDs can also
occur.  Of those, B<challengePassword> is typical.

For API version 0, this method returns a hash consisting of all
attributes in an internal format.  This usage is B<deprecated>.

For API version 1:

If $name is not specified, a list of attribute names is returned.  The list does not
include the requestedExtensions attribute.  For that, use extensions();

If no attributes are present, the empty list (C<undef> in scalar context) is returned.

If $name is specified, the value of the extension is returned.  $name can be specified
as a numeric OID.

In scalar context, a single string is returned, which may include lists and labels.

  cspName="Microsoft Strong Cryptographic Provider",keySpec=2,signature=("",0)

Special characters are escaped as described in options.

In array context, the value(s) are returned as a list of items, which may be references.

 print( " $_: ", scalar $decoded->attributes($_), "\n" )
                                   foreach ($decoded->attributes);


=for readme stop

See the I<Table of known OID names> below for a list of names.

=for readme continue

=begin :readme

See the module documentation for a list of known OID names.

It is too long to include here.

=end :readme

=head2 extensions

Returns an array containing the names of all extensions present in the CSR.  If no extensions are present,
the empty list is returned.

The names vary depending on the API version; however, the returned names are acceptable to C<extensionValue>, C<extensionPresent>, and C<name2oid>.

The values of extensions vary, however the following code fragment will dump most extensions and their value(s).

 print( "$_: ", $decoded->extensionValue($_,1), "\n" ) foreach ($decoded->extensions);


The sample code fragment is not guaranteed to handle all cases.
Production code needs to select the extensions that it understands and should respect
the B<critical> boolean.  B<critical> can be obtained with extensionPresent.

=head2 extensionValue( $name, $format )

Returns the value of an extension by name, e.g. C<extensionValue( 'keyUsage' )>.
The name SHOULD be an API v1 name, but API v0 names are accepted for compatibility.
The name can also be specified as a numeric OID.

If C<$format> is 1, the value is a formatted string, which may include lists and labels.
Special characters are escaped as described in options;

If C<$format> is 0 or not defined, a string, or an array reference may be returned.
The array many contain any Perl variable type.

To interpret the value(s), you need to know the structure of the OID.

=for readme stop

See the I<Table of known OID names> below for a list of names.

=for readme continue

=begin :readme

See the module documentation for a list of known OID names.

It is too long to include here.

=end :readme

=head2 extensionPresent( $name )

Returns B<true> if a named extension is present:
    If the extension is B<critical>, returns 2.
    Otherwise, returns 1, indicating B<not critical>, but present.

If the extension is not present, returns C<undef>.

The name can also be specified as a numeric OID.

=for readme stop

See the I<Table of known OID names> below for a list of names.

=for readme continue

=begin :readme

See the module documentation for a list of known OID names.

It is too long to include here.

=end :readme

=head2 registerOID( )

Class method.

Register a custom OID, or a public OID that has not been added to Crypt::PKCS10 yet.

The OID may be an extension identifier or an RDN component.

The oid is specified as a string in numeric form, e.g. C<'1.2.3.4'>

=head3 registerOID( $oid )

Returns B<true> if the specified OID is registered, B<false> otherwise.

=head3 registerOID( $oid, $longname, $shortname )

Registers the specified OID with the associated long name.  This
enables the OID to be translated to a name in output.

The long name should be Hungarian case (B<commonName>), but this is not currently
enforced.

Optionally, specify the short name used for extracting the subject.
The short name should be upper-case (and will be upcased).

E.g. built-in are C<< $oid => '2.4.5.3', $longname => 'commonName', $shortname => 'CN' >>

To register a shortname for an existing OID without one, specify C<$longname> as C<undef>.

E.g. To register /E for emailAddress, use:
  C<< Crypt::PKCS10->registerOID( '1.2.840.113549.1.9.1', undef, 'e' ) >>


Generates an exception if any argument is not valid, or is in use.

Returns B<true> otherwise.

=head2 checkSignature

Verifies the signature of a CSR.  (Useful if new() specified C<< verifySignature => 0 >>.)

Returns B<true> if the signature is OK.

Returns B<false> if the signature is incorrect.  C<< error() >> returns
the reason.

Returns B<undef> if it was not possible to complete the verification process (e.g. a required
Perl module could not be loaded or an unsupported key/signature type is present.)

I<Note>: Requires Crypt::PK::* for the used algorithm to be installed. For RSA
v1.5 padding is assumed, PSS is not supported (validation fails).


=head2 certificateTemplate

C<CertificateTemplate> returns the B<certificateTemplate> attribute.

Equivalent to C<extensionValue( 'certificateTemplate' )>, which is prefered.

=for readme stop

=head2 Table of known OID names

The following OID names are known.  They are used in returned strings and
structures, and as names by methods such as B<extensionValue>.

Unknown OIDs are returned in numeric form, or can be registered with
B<registerOID>.

=begin MAINTAINER

 To generate the following table, use:
    perl -Mwarnings -Mstrict -MCrypt::PKCS10 -e'Crypt::PKCS10->_listOIDs'

=end MAINTAINER

 OID                        Name (API v1)              Old Name (API v0)
 -------------------------- -------------------------- ---------------------------
 0.9.2342.19200300.100.1.1  userID
 0.9.2342.19200300.100.1.25 domainComponent
 1.2.840.10040.4.1          dsa                        (DSA)
 1.2.840.10040.4.3          dsaWithSha1                (DSA with SHA1)
 1.2.840.10045.2.1          ecPublicKey
 1.2.840.10045.3.1.1        secp192r1
 1.2.840.10045.3.1.7        secp256r1
 1.2.840.10045.4.3.1        ecdsa-with-SHA224
 1.2.840.10045.4.3.2        ecdsa-with-SHA256
 1.2.840.10045.4.3.3        ecdsa-with-SHA384
 1.2.840.10045.4.3.4        ecdsa-with-SHA512
 1.2.840.113549.1.1.1       rsaEncryption              (RSA encryption)
 1.2.840.113549.1.1.2       md2WithRSAEncryption       (MD2 with RSA encryption)
 1.2.840.113549.1.1.3       md4WithRSAEncryption
 1.2.840.113549.1.1.4       md5WithRSAEncryption       (MD5 with RSA encryption)
 1.2.840.113549.1.1.5       sha1WithRSAEncryption      (SHA1 with RSA encryption)
 1.2.840.113549.1.1.6       rsaOAEPEncryptionSET
 1.2.840.113549.1.1.7       RSAES-OAEP
 1.2.840.113549.1.1.10      rsassaPss
 1.2.840.113549.1.1.11      sha256WithRSAEncryption    (SHA-256 with RSA encryption)
 1.2.840.113549.1.1.12      sha384WithRSAEncryption
 1.2.840.113549.1.1.13      sha512WithRSAEncryption    (SHA-512 with RSA encryption)
 1.2.840.113549.1.1.14      sha224WithRSAEncryption
 1.2.840.113549.1.9.1       emailAddress
 1.2.840.113549.1.9.2       unstructuredName
 1.2.840.113549.1.9.7       challengePassword
 1.2.840.113549.1.9.8       unstructuredAddress
 1.2.840.113549.1.9.14      extensionRequest
 1.2.840.113549.1.9.15      smimeCapabilities          (SMIMECapabilities)
 1.3.6.1.4.1.311.2.1.14     CERT_EXTENSIONS
 1.3.6.1.4.1.311.2.1.21     msCodeInd
 1.3.6.1.4.1.311.2.1.22     msCodeCom
 1.3.6.1.4.1.311.10.3.1     msCTLSign
 1.3.6.1.4.1.311.10.3.2     msTimeStamping
 1.3.6.1.4.1.311.10.3.3     msSGC
 1.3.6.1.4.1.311.10.3.4     msEFS
 1.3.6.1.4.1.311.10.3.4.1   msEFSRecovery
 1.3.6.1.4.1.311.10.3.5     msWHQLCrypto
 1.3.6.1.4.1.311.10.3.6     msNT5Crypto
 1.3.6.1.4.1.311.10.3.7     msOEMWHQLCrypto
 1.3.6.1.4.1.311.10.3.8     msEmbeddedNTCrypto
 1.3.6.1.4.1.311.10.3.9     msRootListSigner
 1.3.6.1.4.1.311.10.3.10    msQualifiedSubordination
 1.3.6.1.4.1.311.10.3.11    msKeyRecovery
 1.3.6.1.4.1.311.10.3.12    msDocumentSigning
 1.3.6.1.4.1.311.10.3.13    msLifetimeSigning
 1.3.6.1.4.1.311.10.3.14    msMobileDeviceSoftware
 1.3.6.1.4.1.311.13.1       RENEWAL_CERTIFICATE
 1.3.6.1.4.1.311.13.2.1     ENROLLMENT_NAME_VALUE_PAIR
 1.3.6.1.4.1.311.13.2.2     ENROLLMENT_CSP_PROVIDER
 1.3.6.1.4.1.311.13.2.3     OS_Version
 1.3.6.1.4.1.311.20.2       certificateTemplateName
 1.3.6.1.4.1.311.20.2.2     msSmartCardLogon
 1.3.6.1.4.1.311.21.7       certificateTemplate
 1.3.6.1.4.1.311.21.10      ApplicationCertPolicies
 1.3.6.1.4.1.311.21.20      ClientInformation
 1.3.6.1.5.2.3.5            keyPurposeKdc              (KDC Authentication)
 1.3.6.1.5.5.7.2.1          CPS
 1.3.6.1.5.5.7.2.2          userNotice
 1.3.6.1.5.5.7.3.1          serverAuth
 1.3.6.1.5.5.7.3.2          clientAuth
 1.3.6.1.5.5.7.3.3          codeSigning
 1.3.6.1.5.5.7.3.4          emailProtection
 1.3.6.1.5.5.7.3.8          timeStamping
 1.3.6.1.5.5.7.3.9          OCSPSigning
 1.3.6.1.5.5.7.3.21         sshClient
 1.3.6.1.5.5.7.3.22         sshServer
 1.3.6.1.5.5.7.9.5          countryOfResidence
 1.3.14.3.2.29              sha1WithRSAEncryption      (SHA1 with RSA signature)
 1.3.36.3.3.2.8.1.1.1       brainpoolP160r1
 1.3.36.3.3.2.8.1.1.2       brainpoolP160t1
 1.3.36.3.3.2.8.1.1.3       brainpoolP192r1
 1.3.36.3.3.2.8.1.1.4       brainpoolP192t1
 1.3.36.3.3.2.8.1.1.5       brainpoolP224r1
 1.3.36.3.3.2.8.1.1.6       brainpoolP224t1
 1.3.36.3.3.2.8.1.1.7       brainpoolP256r1
 1.3.36.3.3.2.8.1.1.8       brainpoolP256t1
 1.3.36.3.3.2.8.1.1.9       brainpoolP320r1
 1.3.36.3.3.2.8.1.1.10      brainpoolP320t1
 1.3.36.3.3.2.8.1.1.11      brainpoolP384r1
 1.3.36.3.3.2.8.1.1.12      brainpoolP384t1
 1.3.36.3.3.2.8.1.1.13      brainpoolP512r1
 1.3.36.3.3.2.8.1.1.14      brainpoolP512t1
 1.3.132.0.1                sect163k1
 1.3.132.0.15               sect163r2
 1.3.132.0.16               sect283k1
 1.3.132.0.17               sect283r1
 1.3.132.0.26               sect233k1
 1.3.132.0.27               sect233r1
 1.3.132.0.33               secp224r1
 1.3.132.0.34               secp384r1
 1.3.132.0.35               secp521r1
 1.3.132.0.36               sect409k1
 1.3.132.0.37               sect409r1
 1.3.132.0.38               sect571k1
 1.3.132.0.39               sect571r1
 2.5.4.3                    commonName
 2.5.4.4                    surname                    (Surname)
 2.5.4.5                    serialNumber
 2.5.4.6                    countryName
 2.5.4.7                    localityName
 2.5.4.8                    stateOrProvinceName
 2.5.4.9                    streetAddress
 2.5.4.10                   organizationName
 2.5.4.11                   organizationalUnitName
 2.5.4.12                   title                      (Title)
 2.5.4.13                   description                (Description)
 2.5.4.14                   searchGuide
 2.5.4.15                   businessCategory
 2.5.4.16                   postalAddress
 2.5.4.17                   postalCode
 2.5.4.18                   postOfficeBox
 2.5.4.19                   physicalDeliveryOfficeName
 2.5.4.20                   telephoneNumber
 2.5.4.23                   facsimileTelephoneNumber
 2.5.4.41                   name                       (Name)
 2.5.4.42                   givenName
 2.5.4.43                   initials
 2.5.4.44                   generationQualifier
 2.5.4.45                   uniqueIdentifier
 2.5.4.46                   dnQualifier
 2.5.4.51                   houseIdentifier
 2.5.4.65                   pseudonym
 2.5.29.14                  subjectKeyIdentifier       (SubjectKeyIdentifier)
 2.5.29.15                  keyUsage                   (KeyUsage)
 2.5.29.17                  subjectAltName
 2.5.29.19                  basicConstraints           (Basic Constraints)
 2.5.29.32                  certificatePolicies
 2.5.29.32.0                anyPolicy
 2.5.29.37                  extKeyUsage                (EnhancedKeyUsage)
 2.16.840.1.101.3.4.2.1     sha256                     (SHA-256)
 2.16.840.1.101.3.4.2.2     sha384                     (SHA-384)
 2.16.840.1.101.3.4.2.3     sha512                     (SHA-512)
 2.16.840.1.101.3.4.2.4     sha224                     (SHA-224)
 2.16.840.1.101.3.4.3.1     dsaWithSha224
 2.16.840.1.101.3.4.3.2     dsaWithSha256
 2.16.840.1.101.3.4.3.3     dsaWithSha384
 2.16.840.1.101.3.4.3.4     dsaWithSha512
 2.16.840.1.113730.1.1      netscapeCertType
 2.16.840.1.113730.1.2      netscapeBaseUrl
 2.16.840.1.113730.1.4      netscapeCaRevocationUrl
 2.16.840.1.113730.1.7      netscapeCertRenewalUrl
 2.16.840.1.113730.1.8      netscapeCaPolicyUrl
 2.16.840.1.113730.1.12     netscapeSSLServerName
 2.16.840.1.113730.1.13     netscapeComment
 2.16.840.1.113730.4.1      nsSGC

=for readme continue

=begin :readme

=head1 CHANGES

=for readme include file=Changes type=text start=^1\.0 stop=^__END__

For a more detailed list of changes, see F<Commitlog> in the distribution.

=end :readme

=head1 EXAMPLES

In addition to the code snippets contained in this document, the F<examples/> directory of the distribution
contains some sample utilitiles.

Also, the F<t/> directory of the distribution contains a number of tests that exercise the
API.  Although artificial, they are another good source of examples.

Note that the type of data returned when extracting attributes and extensions is dependent
on the specific OID used.

Also note that some functions not listed in this document are tested.  The fact that they are
tested does not imply that they are stable, or that they will be present in any future release.

The test data was selected to exercise the API; the CSR contents are not representative of
realistic certificate requests.

=head1 ACKNOWLEDGEMENTS

Martin Bartosch contributed preliminary EC support:  OIDs and tests.

Timothe Litt made most of the changes for V1.4+

C<Crypt::PKCS10> is based on the generic ASN.1 module by Graham Barr and on the
 x509decode example by Norbert Klasen. It is also based upon the
works of Duncan Segrest's C<Crypt-X509-CRL> module.

=head1 AUTHORS

Gideon Knocke <gknocke@cpan.org>
Timothe Litt <tlhackque@cpan.org>

=head1 LICENSE

GPL v1 -- See LICENSE file for details

=cut
