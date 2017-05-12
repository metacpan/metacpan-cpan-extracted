package Convert::X509::Parser;

=head1 NAME

Convert::X509::Parser core module to parse X509 requests, certificates and CRLs

=cut

use Carp;
use strict;
use warnings;
use Convert::ASN1;
use MIME::Base64;

#use Data::Dumper;

my $iconv={ # many troubles with localized 'DirectoryString' values...
	'0' => undef, # stub
	'utf8String'=> undef, # already contains wide-characters
	'bmpString'	=> 'UTF-16BE', # CEnroll (win)object produces such byte-oriented value
	'universalString'	=> 'UTF-16BE', # ??? never seen, may be UTF-16LE or undef
   'integer'	=> undef,
	'ia5String'	=> undef,
	'teletexString'	=> undef,
	'printableString'	=> undef,
};

my %oid_db=(
	'CRL'	=> { 'asn'=>'CertificateList' },
	'REQ'	=> { 'asn'=>'CertificationRequest' },
	'CERT'	=> { 'asn'=>'Certificate' },
   'PKCS7'	=> { 'asn'=>'ContentInfo' },
	# PKCS7 messages
	'1.2.840.113549.1.7.1'	=> { 'asn'=>'Data' },
	'1.2.840.113549.1.7.2'	=> { 'asn'=>'SignedData' },
	'1.2.840.113549.1.7.3'	=> { 'asn'=>'EnvelopedData' },
	'1.2.840.113549.1.7.4'	=> { 'asn'=>'SignedAndEnvelopedData' },
	'1.2.840.113549.1.7.5'	=> { 'asn'=>'DigestedData' },
	'1.2.840.113549.1.7.6'	=> { 'asn'=>'EncryptedData' },
	# subject
	'DS'	=> { 'asn'=>'DirectoryString' },
	'2.5.4.3'	=> { 'desc'=>'CN'	}, # name and surname
	'2.5.4.6' 	=> { 'desc'=>'C'	},	# Country
	'2.5.4.7' 	=> { 'desc'=>'L'	},	# city (Location)
	'2.5.4.8' 	=> { 'desc'=>'S'	},	# region (State)
	'2.5.4.10'	=> { 'desc'=>'O'	},	# Organization
	'2.5.4.11'	=> { 'desc'=>'OU'	},	# OrgUnit
	'2.5.4.12'	=> { 'desc'=>'T'	},	# position (Title)
	'1.2.840.113549.1.9.1'
	         	=> { 'desc'=>'E'	},	# Email
	# GOST crypto
	'1.2.643.2.2.3'	=> { 'desc'=>'GOST R 34.11/34.10-2001'	},
	'1.2.643.2.2.4'	=> { 'desc'=>'GOST R 34.11/34.10-94'	},
	'1.2.643.2.2.9'	=> { 'desc'=>'GOST R 34.11-94'	},
	'1.2.643.2.2.19'	=> { 'desc'=>'GOST R 34.10-2001'	},
	'1.2.643.2.2.20'	=> { 'desc'=>'GOST R 34.10-94'	},
	'1.2.643.2.2.21'	=> { 'desc'=>'GOST 28147-89'	},
	# RSA crypto
	'1.2.840.113549.1.1.1'	=> { 'desc'=>'RSA encryption'	},
	'1.2.840.113549.1.1.4'	=> { 'desc'=>'MD5 with RSA encryption'	},
	'1.2.840.113549.1.1.5'	=> { 'desc'=>'SHA1 with RSA encryption'	},
	'1.2.840.113549.1.1.11'	=> { 'desc'=>'SHA256 with RSA encryption'	},
	# CRL
	'2.5.29.21'	=> { 'desc'=>'Revocation reason', 'asn'=>'CRLReason',
                    'enum'=>['Unspecified', 'Key Compromise', 'CA Compromise', 'Affiliation Changed',
                             'Superseded', 'Cessation Of Operation', 'Certificate Hold',
                             'Remove From CRL', 'Privilege Withdrawn', 'AA Compromise'],
                  },
	'2.5.29.20'	=> { 'desc'=>'CRL number', 'asn'=>'CRLNumber'},
	'2.5.29.35'	=> { 'desc'=>'Authority key identifier', 'asn'=>'AuthorityKeyIdentifier'},

	# Extensions
	'1.3.6.1.4.1.311.2.1.14'	=> { 'desc'=>'M$ Certificate request extensions', 'asn'=>'Extensions' },
	'1.2.840.113549.1.9.14'	=> { 'desc'=>'RSA Certificate request extensions', 'asn'=>'Extensions' },
	'1.2.840.113549.1.9.15'	=> { 'desc'=>'S/Mime capabilities', 'asn'=>'SMIMECapabilities' },
	'1.3.6.1.4.1.311.13.2.3'	=> { 'desc'=>'M$ OS Version', 'asn'=>'DirectoryString' },
	'1.3.6.1.4.1.311.13.2.2'	=> { 'desc'=>'M$ ENROLLMENT_CSP_PROVIDER', 'asn'=>'EnrollmentCSPProvider' },
	'1.3.6.1.4.1.311.21.1'	=> { 'desc'=>'M$ CERTSRV_CA_VERSION', 'asn'=>'DirectoryString' },
	'1.3.6.1.4.1.311.21.4'	=> { 'desc'=>'M$ next CRL publish date', 'asn'=>'Time' },
	'1.3.6.1.4.1.311.21.14'	=> { 'desc'=>'M$ CRL_SELF_CDP', 'asn'=>'CRLDistributionPoints' },
	'1.3.6.1.4.1.27952'		=> { 'desc'=>'Расширения ГПБ (ОАО)' },
	'1.3.6.1.4.1.27952.0.1'		=> { 'desc'=>'Контейнер ключа ГПБ (ОАО)', 'asn'=>'DirectoryString'},
	'1.3.6.1.5.5.7.1.1'	=> { 'desc'=>'Subject Info Access', 'asn'=>'SubjectInfoAccessSyntax'},
	'2.5.29.15'	=> { 'desc'=>'Key Usage', 'asn'=>'KeyUsage',
                    'bits'=>['Digital Signature', 'Non Repudiation', 'Key Encipherment',
                             'Data Encipherment', 'Key Agreement', 'Key CertSign',
                             'CRL Sign', 'Encipher Only', 'Decipher Only'],
                  },
	'2.5.29.2'	=> { 'desc'=>'Key Attributes', 'asn'=>'KeyAttributes' },
	'2.5.29.31'	=> { 'desc'=>'CRL distribution points', 'asn'=>'CRLDistributionPoints'},
	'2.5.29.32'	=> { 'desc'=>'Certificate policies', 'asn'=>'CertificatePolicies'},
	'2.5.29.46'	=> { 'desc'=>'Freshest CRL distribution points', 'asn'=>'CRLDistributionPoints'},
	'2.5.29.9'	=> { 'desc'=>'Subject directory attributes', 'asn'=>'SubjectDirectoryAttributes'},
	'2.5.29.19'	=> { 'desc'=>'Basic constraints', 'asn'=>'BasicConstraints'},
	'2.5.29.17'	=> { 'desc'=>'Subject Alternative Name', 'asn'=>'GeneralNames'},
	'2.5.29.18'	=> { 'desc'=>'Issuer Alternative Name', 'asn'=>'GeneralNames'},
	'1.2.840.113533.7.65.0'	=> { 'desc'=>'Entrust version info', 'asn'=>'EntrustVersionInfo'},

	# Enhanced Key Usage
	'2.5.29.37'	=> { 'desc'=>'Enhanced Key Usage', 'asn'=>'EnhancedKeyUsage' },
	'1.3.6.1.5.5.7.3.1'	=> { 'desc'=>'Server Authentication' },
	'1.3.6.1.5.5.7.3.2'	=> { 'desc'=>'Client Authentication' },
	'1.3.6.1.5.5.7.3.3'	=> { 'desc'=>'Code Signing' },
	'1.3.6.1.5.5.7.3.4'	=> { 'desc'=>'Secure Email' },
	'1.3.6.1.4.1.311.20.2.2'	=> { 'desc'=>'Smart Card Logon' },
	'1.2.643.2.2.34.2'	=> { 'desc'=>'Временный доступ к Центру Регистрации' },
	'1.2.643.2.2.34.6'	=> { 'desc'=>'Пользователь Центра Регистрации, HTTP, TLS клиент' },

);

my $asn;
# stub localization
my $cp_from='latin1';
my $cp_to='latin1';

sub _set_cp {
  (undef,$cp_to,$cp_from) = @_;
  $cp_from='latin1' unless $cp_from;
  $cp_to='latin1' unless $cp_to;
}

sub _ansi_now{
# in: datetime in seconds
# out: list ('yyyy-mm-dd', 'HH:MM:SS')
	my ($sec,$min,$hh,$dd,$mm,$yyyy)=localtime(shift || time());
	my ($d,$t) =
		(
			1900+$yyyy . '-' .
			 (++$mm<10 ? '0' : '') . $mm . '-' .
			 ($dd<10 ? '0' : '') . $dd,

			($hh<10 ? '0' : '') . $hh . ':' .
			 ($min<10 ? '0' : '') . $min . ':' .
			 ($sec<10 ? '0' : '') . $sec
		);
	return(wantarray ? ($d,$t) : "$d $t");
}

sub _prepare {
  my ($pdata, $debug) = @_;
  warn ('Parameter must be a scalar ref') and return undef unless ref($pdata) eq 'SCALAR';
  unless (unpack('H3',$$pdata) eq '308'){ # first 2 bytes for ASN.1 SEQUENCE
    $$pdata = join("\n",
        $$pdata =~ m!^([A-Za-z01-9+/]{1,}[-=]*)$!gm );
    warn $$pdata if $debug;
    $$pdata = decode_base64($$pdata);
  }
}

sub _oid2txt {
  my @res = map { ref($_) ? $_->{'desc'} || $_->{'asn'} : $_ }
                map { $oid_db{$_} || $_ } @_;
  return (wantarray() ? @res : $res[0] || '');
}

sub _int2hexstr {
  my $res='';
  my $m=$_[0];
  while ($m){
	  $res = unpack('H2',pack('C', $m & 255 )) . $res;
	  $m >>= 8;
  }
  return $res;
}

sub _iconv {
  # decoding hash pair like {'anyString'=>'Localized value'}
  my ($data,$fmt,$from,$to) = @_;
  $from = $cp_from unless $from;
  $to = $cp_to unless $to;
  # belt-and-suspenders approach...
  return Encode::str2bytes($to,$data) if Encode::is_utf8($data);
  $data=Encode::bytes2str($iconv->{$fmt},$data) if $iconv->{$fmt};
  return Encode::str2bytes($to,$data) if Encode::is_utf8($data);
  Encode::from_to($data, $from, $to);
  return $data;
}

sub _localize {
  my ($k,$v) = %{ shift @_};
  return _iconv($v,$k,@_);
}

sub _decode {
  die ("Error\n",$asn->error,"\nin ASN.1 code ") if $asn->error;
  my $type = shift;
  my $node= $asn->find( $oid_db{uc($type)}->{'asn'} || 'Any' );
  die ('Error finding ',$type,'-', $oid_db{uc($type)}->{'asn'}, ' in module') unless $node;
  my @decoded = map {$node->decode($_)} @_;
  return ( @_ > 1 ? [@decoded] : $decoded[0] )
}

sub _decode_rdn {
  my $res = {};
  return $res unless ref($_[0]) eq 'ARRAY';
  for my $rdn ( @{ $_[0] } ){
    for my $attr (@$rdn){ # = { 'type'=>OID, 'value'=>{dsType=>DirectoryString} }
      push  @{ $res->{$attr->{'type'}} },
        $attr->{'value'};
    }
  }
  return $res;
}

sub _decode_ext {
  my $res = {};
  for (@_){
    next unless ref($_) eq 'ARRAY';
    for my $ext (@$_){
      # RFC 3280 :
      # "A certificate MUST NOT include more than one instance of a particular extension"
      warn 'Duplicated extension ', $ext->{'extnID'} && next
        if exists $res->{$ext->{'extnID'}};
      $res->{$ext->{'extnID'}}{'value'} = _decode( $ext->{'extnID'}, $ext->{'extnValue'} );
      $res->{$ext->{'extnID'}}{'critical'} = 1 if $ext->{'critical'};
    }
  }
  return $res;
}

sub _rdn2hash {
	my $rdn = shift;
	return undef unless ref($rdn) eq 'HASH';
	my %h;
	while(my ($k,$v) = each %$rdn){
		$h{_oid2txt($k)} = [map {_localize($_, @_)} @$v];
	}
	return %h;
}

sub _eku {
  my ($self) = @_;
  my $oids = $self->{'extensions'}{'2.5.29.37'}{'value'};
  return ($oids ? _oid2txt(@$oids) : () );
}

sub _bits2str {
  my ($oid,$b) = @_;
  return '' unless ref($b) eq 'ARRAY';
  my $mask = [split(//, unpack('B*',$b->[0]) )];
  return
    @{$oid_db{$oid}{'bits'} }
    [ grep {$mask->[$_]} (0 .. $b->[1]-1) ];
}

sub _keyusage {
  return _bits2str('2.5.29.15', $_[0]->{'extensions'}{'2.5.29.15'}{'value'});
}

sub _crlreason {
  return $oid_db{'2.5.29.21'}{'enum'}[ $_[0] || 0 ] ;
}


$asn = Convert::ASN1->new;
$asn->prepare(<<ASN1);

Any ::= ANY
SequenceAny ::= SEQUENCE OF ANY
SetAny ::= SET OF ANY

Validity ::= SEQUENCE {
	notBefore Time,
	notAfter  Time}

Time ::= CHOICE {
-- A few things will work with GTime
	generalTime GeneralizedTime,
	utcTime     UTCTime
}

UniqueIdentifier ::= BIT STRING

DirectoryString ::= CHOICE {
      teletexString   TeletexString,
      printableString PrintableString,
      bmpString       BMPString,
      universalString UniversalString,
      utf8String      UTF8String,
      ia5String       IA5String,
      integer         INTEGER}

Name ::= CHOICE { rdnSequence RDNSequence }
RDNSequence ::= SEQUENCE OF RelativeDistinguishedName
RelativeDistinguishedName ::= SET OF AttributeTypeAndValue
AttributeTypeAndValue ::= SEQUENCE {
	type	OBJECT IDENTIFIER,
	value DirectoryString}

Attributes ::= SET OF Attribute
Attribute ::= SEQUENCE {
  type   OBJECT IDENTIFIER,
  values SET OF ANY}

AlgorithmIdentifier ::= SEQUENCE {
  algorithm  OBJECT IDENTIFIER,
  parameters ANY DEFINED BY algorithm OPTIONAL}

SubjectPublicKeyInfo ::= SEQUENCE {
  algorithm        AlgorithmIdentifier,
  subjectPublicKey BIT STRING}

Extensions ::= SEQUENCE OF Extension
Extension ::= SEQUENCE {
  extnID    OBJECT IDENTIFIER,
  critical  BOOLEAN OPTIONAL, -- DEFAULT FALSE
  extnValue OCTET STRING}

--- Certificate Request ---

CertificationRequest ::= SEQUENCE {
  certificationRequestInfo CertificationRequestInfo,
  signatureAlgorithm	AlgorithmIdentifier,
  signature          BIT STRING}

CertificationRequestInfo ::= SEQUENCE {
  version       INTEGER ,
  subject       Name,
  subjectPKInfo SubjectPublicKeyInfo,
  attributes    [0] Attributes OPTIONAL}

--- Certificate ---

Certificate ::= SEQUENCE  {
	tbsCertificate		TBSCertificate,
	signatureAlgorithm	AlgorithmIdentifier,
	signature		BIT STRING}

TBSCertificate  ::=  SEQUENCE  {
	version      [0] EXPLICIT INTEGER OPTIONAL,  --DEFAULT v1
	serialNumber INTEGER,
	signature    AlgorithmIdentifier,
	issuer       Name,
	validity     Validity,
	subject      Name,
	subjectPKInfo	SubjectPublicKeyInfo,
	issuerUniqueID	      [1] IMPLICIT UniqueIdentifier OPTIONAL,
		-- If present, version shall be v2 or v3
	subjectUniqueID	   [2] IMPLICIT UniqueIdentifier OPTIONAL,
		-- If present, version shall be v2 or v3
	extensions	         [3] EXPLICIT Extensions OPTIONAL }
		-- If present, version shall be v3

GeneralNames ::= SEQUENCE OF GeneralName
GeneralName ::= CHOICE {
     otherName                       [0]     AnotherName,
     rfc822Name                      [1]     IA5String,
     dNSName                         [2]     IA5String,
     x400Address                     [3]     ANY, --ORAddress,
     directoryName                   [4]     Name,
     ediPartyName                    [5]     EDIPartyName,
     uniformResourceIdentifier       [6]     IA5String,
     iPAddress                       [7]     OCTET STRING,
     registeredID                    [8]     OBJECT IDENTIFIER }
AnotherName ::= SEQUENCE {
     type    OBJECT IDENTIFIER,
     value      [0] EXPLICIT ANY } --DEFINED BY type-id }
EDIPartyName ::= SEQUENCE {
     nameAssigner            [0]     DirectoryString OPTIONAL,
     partyName               [1]     DirectoryString}

-- CRL --

CertificateList ::= SEQUENCE  {
  tbsCertList          TBSCertList,
  signatureAlgorithm   AlgorithmIdentifier,
  signatureValue       BIT STRING}

TBSCertList ::= SEQUENCE  {
  version                 INTEGER OPTIONAL,  -- if present, MUST be v2
  signature               AlgorithmIdentifier,
  issuer                  Name,
  thisUpdate              Time,
  nextUpdate              Time OPTIONAL,
  revokedCertificates     RevokedCertificates OPTIONAL,
  crlExtensions           [0]  EXPLICIT Extensions OPTIONAL}

RevokedCertificates ::= SEQUENCE OF RevokedCerts

RevokedCerts ::= SEQUENCE  {
	userCertificate         INTEGER,
	revocationDate          Time,
	crlEntryExtensions      Extensions OPTIONAL}

CRLReason ::= ENUMERATED {
        unspecified             (0),
        keyCompromise           (1),
        cACompromise            (2),
        affiliationChanged      (3),
        superseded              (4),
        cessationOfOperation    (5),
        certificateHold         (6),
        removeFromCRL           (8),
        privilegeWithdrawn      (9),
        aACompromise           (10)}

CRLNumber ::= INTEGER

AuthorityKeyIdentifier ::= SEQUENCE {
      keyIdentifier             [0] OCTET STRING OPTIONAL,
      authorityCertIssuer       [1] GeneralNames OPTIONAL,
      authorityCertSerialNumber [2] INTEGER      OPTIONAL }
    -- authorityCertIssuer and authorityCertSerialNumber shall both
    -- be present or both be absent

-- Specific structures --
EnhancedKeyUsage ::= SEQUENCE OF OBJECT IDENTIFIER

KeyUsage ::= BIT STRING -- see OID db for 2.5.29.15

EnrollmentCSPProvider ::= SEQUENCE  {
  int INTEGER,
  ds DirectoryString,
  bs BIT STRING}

CRLDistributionPoints  ::= SEQUENCE OF DistributionPoint
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

KeyAttributes ::= SEQUENCE {
  keyID OCTET STRING OPTIONAL,
  keyUsage KeyUsage OPTIONAL,
  validity PrivateKeyUsagePeriod OPTIONAL}
PrivateKeyUsagePeriod::= SEQUENCE {
        notBefore       [0]     GeneralizedTime OPTIONAL,
        notAfter        [1]     GeneralizedTime OPTIONAL }

CertificatePolicies ::= SEQUENCE OF PolicyInformation
PolicyInformation ::= SEQUENCE {
     policyIdentifier   OBJECT IDENTIFIER,
     policyQualifiers   SEQUENCE OF
             PolicyQualifierInfo OPTIONAL }
PolicyQualifierInfo ::= SEQUENCE {
       policyQualifierId  OBJECT IDENTIFIER,
       qualifier        ANY } --DEFINED BY policyQualifierId }

SubjectInfoAccessSyntax ::= SEQUENCE OF AccessDescription
AccessDescription  ::=  SEQUENCE {
        accessMethod          OBJECT IDENTIFIER,
        accessLocation        GeneralName  }

BasicConstraints ::= SEQUENCE {
     cA                      BOOLEAN OPTIONAL, --DEFAULT FALSE,
     pathLenConstraint       INTEGER OPTIONAL }

SMIMECapabilities ::= SEQUENCE OF SMIMECapability
SMIMECapability ::= SEQUENCE {
    capability OBJECT IDENTIFIER,
    parameters ANY OPTIONAL
}

----------------------------------
-- never seen theese (V) extensions
EntrustVersionInfo ::= SEQUENCE {
              entrustVers  GeneralString,
              entrustInfoFlags EntrustInfoFlags }
EntrustInfoFlags::= BIT STRING

SubjectDirectoryAttributes ::= SEQUENCE OF Attribute

NameConstraints ::= SEQUENCE {
  permittedSubtrees       [0]     GeneralSubtrees OPTIONAL,
  excludedSubtrees        [1]     GeneralSubtrees OPTIONAL }
GeneralSubtrees ::= SEQUENCE OF GeneralSubtree
GeneralSubtree ::= SEQUENCE {
  base     GeneralName,
  minimum  [0] INTEGER OPTIONAL,
  maximum  [1] INTEGER OPTIONAL }
-- never seen theese (^) extensions
----------------------------------

ASN1

1;
