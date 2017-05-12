package Convert::X509::minipkcs7;

=head1 NAME

Convert::X509::minipkcs7 - parse pkcs7 messages just to get only
SN list of recipients/signers
and correspondent crypto-algorithmes

=head1 SYNOPSYS

 use Convert::X509::minipkcs7;
 use Data::Dumper;

 open(F,'<', $ARGV[0]) or die;
 binmode(F);
 local $/;
 my $data=Convert::X509::minipkcs7->new(<F>);
 print Dumper($data->snlist());
        
=cut

use strict;
use warnings;
use Convert::ASN1;
use MIME::Base64;

my %oid_db=(
   'PKCS7'	=> { 'asn'=>'ContentInfo' },
	'1.2.840.113549.1.7.1'	=> { 'asn'=>'Data' },
	'1.2.840.113549.1.7.2'	=> { 'asn'=>'SignedData' },
	'1.2.840.113549.1.7.3'	=> { 'asn'=>'EnvelopedData' },
	'1.2.840.113549.1.7.4'	=> { 'asn'=>'SignedAndEnvelopedData' },
	'1.2.840.113549.1.7.5'	=> { 'asn'=>'DigestedData' },
	'1.2.840.113549.1.7.6'	=> { 'asn'=>'EncryptedData' },
);

my $asn;

sub _prepare {
  my ($pdata) = @_;
  warn ('Parameter must be a scalar ref') && return undef unless ref($pdata) eq 'SCALAR';
  # first bytes for ASN.1 SEQUENCE are 3080 or 3082
  unless (unpack('H3',$$pdata) eq '308'){
    $$pdata = decode_base64(
      join("\n",
        $$pdata =~ m!^([A-Za-z01-9+/]{1,})[-=]*$!gm
      )
    );
  }
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

sub _decode {
  warn ("Error\n",$asn->error,"\nin ASN.1 code\n") && return undef if $asn->error;
  my $type = shift;
  my $node= $asn->find( $oid_db{uc($type)}->{'asn'} || 'Any' );
  warn ('Error finding ',$type,'-', $oid_db{uc($type)}->{'asn'}, ' in module',"\n") && return undef unless $node;
  my @decoded = map {$node->decode($_)} @_;
  return ( @_ > 1 ? [@decoded] : $decoded[0] )
}

sub snlist {
	my ($self) = @_;
	my $res = { }; # {'recipients'=>[],'signers'=>[]};
	if (exists $self->{'content'}{'signerInfos'}){
		@{ $res->{'signers'} } =
			map{
			 {_int2hexstr( $_->{'issuerAndSerialNumber'}{'serialNumber'} ) =>
			 $_->{'digestAlgorithm'}{'algorithm'} }
			}
			@{ $self->{'content'}{'signerInfos'} }
		;
#		for (@{ $self->{'content'}{'signerInfos'} }) {
#			push @{ $res->{'signers'} },
#			 _int2hexstr( $_->{'issuerAndSerialNumber'}{'serialNumber'} );
	}
	if (exists $self->{'content'}{'recipientInfos'}){
	for (@{ $self->{'content'}{'recipientInfos'}{'riSet'} }) {
		my ($kkey) = keys %$_; # RecipientInfo is "CHOICE", so there is only one key

		my $k = $_->{$kkey}{'self'} || $_->{$kkey};
		# damn Signalcom again...

		my $e;
		# known cases
		# case one - keyAgreementRecipientInfo
		$e = (exists $k->{'recipientEncryptedKeys'} ?
			_int2hexstr(
			$k->{'recipientEncryptedKeys'}[0]{'recipientIdentifier'}
			 {'issuerAndSerialNumber'}{'serialNumber'}
			# I don't have any reason to "foreach" in two those lists ([0] and [0] above)
			) : undef
		);
		push @{ $res->{'recipients'} },
		 {$e=>$k->{'keyEncryptionAlgorithm'}{'algorithm'}} if($e);

		# case two - keyTransportRecipientInfo
		$e = (exists $k->{'rid'} ?
			_int2hexstr($k->{'rid'}{'issuerAndSerialNumber'}{'serialNumber'})
			: undef);
		push @{ $res->{'recipients'} },
		 {$e=>$k->{'keyEncryptionAlgorithm'}{'algorithm'}} if($e);
	}
	}
  return $res;
}

sub new {
	my $self={};
	my $class = shift;
	my $pdata = (ref($_[0]) ? $_[0] : \$_[0]);
	my (undef, $debug) = @_;
	_prepare($pdata);
	unless (unpack('H3',$$pdata) eq '308'){
		warn ('Seems to be not PKCS7 data',"\n") if $debug;
		return undef;
	}
	$self = _decode('pkcs7'=>$$pdata);
	unless ($self){
		warn ('PKCS7 Error decoding',"\n") if $debug;
		return undef;
	}
	my $content = $self->{'content'};
	$content = _decode( $self->{'contentType'} => $content );

	# ASN.1 bug, sorry Graham...
	unless($content){
		$content = $self->{'content'} . pack('H*','0000');
		$content = _decode( $self->{'contentType'} => $content );
	}

	unless ($content){
		warn ('PKCS7 Error decoding content, type ' ,
		 $self->{'contentType'},"\n") if $debug;
		return undef;
	}
	$self->{'content'} = $content;

	return bless($self,$class);
}

$asn = Convert::ASN1->new;
$asn->prepare(<<ASN1);

-- http://www.ietf.org/rfc/rfc2315.txt
-- http://www.ietf.org/rfc/rfc3369.txt
-- http://www.alvestrand.no/objectid
-- http://www.itu.int/ITU-T/asn1/database
-- BUT BE CAREFUL !!!

Any ::= ANY -- do not remove!

ContentInfo ::= SEQUENCE {
      contentType OBJECT IDENTIFIER,
      content [0] EXPLICIT ANY }

EnvelopedData ::=  SEQUENCE {
          version INTEGER,
          originatorInfo [0] ANY OPTIONAL,
          recipientInfos RecipientInfos,
          encryptedContentInfo EncryptedContentInfo,
          unprotectedAttrs [1] ANY OPTIONAL
}

RecipientInfos ::= CHOICE {
  riSet SET OF RecipientInfo
}

RecipientInfo ::= CHOICE {
  keyTransportRecipientInfo	KeyTransRecipientInfo,
  keyAgreementRecipientInfo	[1] KeyAgreementRecipientInfo,
  kekri [2] ANY, -- KEKRecipientInfo
  pwri [3] ANY, -- PasswordRecipientinfo
  ori [4] ANY -- OtherRecipientInfo
}

KeyTransRecipientInfo ::= SEQUENCE {
  version INTEGER,  -- always set to 0 or 2
  rid RecipientIdentifier,
  keyEncryptionAlgorithm AlgorithmIdentifier, --KeyEncryptionAlgorithmIdentifier
  encryptedKey EncryptedKey
}
EncryptedKey ::= OCTET STRING
RecipientIdentifier ::= CHOICE {
     issuerAndSerialNumber IssuerAndSerialNumber,
     subjectKeyIdentifier [0] ANY -- SubjectKeyIdentifier
}

KeyAgreementRecipientInfo ::= SEQUENCE {
-- ! ! ! ! !
-- Damn nonstandard Signalcom solutions for GOST94 and 2001
-- when structures differ only by inherited SEQUENCE
-- I have real doubt for right working such crutch
-- ! ! ! ! !
  self                    KeyAgreementRecipientInfo OPTIONAL,
  version                 INTEGER OPTIONAL,
  originator              ANY OPTIONAL,
  userKeyingMaterial      [1] ANY OPTIONAL,
  keyEncryptionAlgorithm  AlgorithmIdentifier OPTIONAL,
  recipientEncryptedKeys  SEQUENCE OF RecipientEncryptedKey OPTIONAL
}

RecipientEncryptedKey ::= SEQUENCE {
  recipientIdentifier  SomebodyIdentifier,
  encryptedKey         ANY
}
SomebodyIdentifier ::= CHOICE {
  issuerAndSerialNumber  IssuerAndSerialNumber,
  recipientKeyIdentifier [0] ANY,
  subjectKeyIdentifier   [2] ANY
}
IssuerAndSerialNumber ::= SEQUENCE {
  issuer        ANY,
  serialNumber  INTEGER
}

SignedAndEnvelopedData ::= SEQUENCE {
  version               INTEGER,
  recipientInfos        RecipientInfos,
  digestAlgorithms      DigestAlgorithmIdentifiers,
  encryptedContentInfo  EncryptedContentInfo,
  certificates          [0] ANY OPTIONAL,
  crls                  [1] ANY OPTIONAL,
  signerInfos           SET OF SignerInfo }

SignedData ::= SEQUENCE {
     version INTEGER,
     digestAlgorithms DigestAlgorithmIdentifiers,
     contentInfo EncapsulatedContentInfo,
     certificates [0] ANY OPTIONAL,
     crls [1] ANY OPTIONAL,
     signerInfos SET OF SignerInfo }
SignerInfo ::= SEQUENCE {
     version INTEGER,
     issuerAndSerialNumber IssuerAndSerialNumber,
     digestAlgorithm AlgorithmIdentifier,
     authenticatedAttributes [0] ANY OPTIONAL,
     digestEncryptionAlgorithm AlgorithmIdentifier,
     encryptedDigest ANY,
     unauthenticatedAttributes [1] ANY OPTIONAL }
DigestAlgorithmIdentifiers ::= SET OF AlgorithmIdentifier

DigestedData ::= SEQUENCE {
  version          INTEGER,
  digestAlgorithm  AlgorithmIdentifier,
  contentInfo      ContentInfo,
  digest           ANY }
EncryptedData ::= SEQUENCE {
  version                INTEGER,
  encryptedContentInfo   EncryptedContentInfo,
  unprotectedAttributes  [1] ANY OPTIONAL }

EncryptedContentInfo ::= SEQUENCE {
  contentType          OBJECT IDENTIFIER,
  contentEncAlgorithm  AlgorithmIdentifier,
  encryptedContent     ANY OPTIONAL}

EncapsulatedContentInfo ::= SEQUENCE {
        eContentType OBJECT IDENTIFIER,
        eContent [0] EXPLICIT OCTET STRING OPTIONAL }
Data ::= OCTET STRING

--------------------------------

AlgorithmIdentifier ::= SEQUENCE {
  algorithm  OBJECT IDENTIFIER,
  parameters ANY DEFINED BY algorithm OPTIONAL}

ASN1

1;
