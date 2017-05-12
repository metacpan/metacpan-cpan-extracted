# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Crypt-X509.t'
use Test::More tests => 68;
use Math::BigInt;
BEGIN { use_ok('Crypt::X509') }

$cert = loadcert('t/verisign.der');
is( length $cert, 774, 'certificate file loaded' );
$decoded = Crypt::X509->new( cert => $cert );
ok( defined $decoded,             'new() returned something' );
ok( $decoded->isa('Crypt::X509'), 'and it\'s the right class' );
is( $decoded->error,     undef,      'decode successful' );
is( $decoded->not_after, 1848787199, 'not_after got parsed' );
is( join( ',', @{ $decoded->Issuer } ), join( ',', @{ $decoded->Subject } ), 'Root CA: Subject equals Issuer' );

$cert = loadcert('t/aj.cer');
$decoded2 = Crypt::X509->new( cert => $cert );
is( $decoded2->error, undef, 'decode successful' );
is( join( ':', @{ $decoded2->KeyUsage } ), "critical:digitalSignature:keyEncipherment:dataEncipherment", 'Keyusagecheck' );
is( join( ':', @{ $decoded2->ExtKeyUsage } ), "clientAuth:emailProtection", 'Extkeyusagecheck' );
# this has also to work twice
is( join( ':', @{ $decoded2->KeyUsage } ), "critical:digitalSignature:keyEncipherment:dataEncipherment", 'Keyusagecheck again' );
is( join( ':', @{ $decoded2->ExtKeyUsage } ), "clientAuth:emailProtection", 'Extkeyusagecheck again' );
is( join( ',', @{ $decoded2->Subject } ), "E=alexander.jung\@allianz.de,C=DE,O=Allianz Group,CN=Alexander Jung", 'Subject parsed' );
is( $decoded2->subject_country, "DE",                         "Subject_country" );
is( $decoded2->subject_state,   undef,                        "Subject_state" );
is( $decoded2->subject_org,     "Allianz Group",              "Subject_org" );
is( $decoded2->subject_ou,      undef,                        "Subject_ou" );
is( $decoded2->subject_email,   "alexander.jung\@allianz.de", "Subject_email" );
is( join( ',', @{ $decoded2->Issuer } ), "C=DE,O=Allianz Group,CN=Allianz Dresdner CA", "Issuer Parsed");
is( $decoded2->issuer_cn,           "Allianz Dresdner CA",  "Issuer_cn" );
is( $decoded2->issuer_country,      "DE",                   "Isssuer_country" );
is( $decoded2->issuer_state,        undef,                  "Issuer_state" );
is( $decoded2->issuer_locality,     undef,                  "Issuer_locality" );
is( $decoded2->issuer_org,          "Allianz Group",        "Issuer_org" );
is( $decoded2->issuer_email,        undef,                  "Issuer_email" );
is( $decoded2->pubkey_algorithm,    "1.2.840.113549.1.1.1", "pubkey_algorithm" );
is( $decoded2->sig_algorithm,       "1.2.840.113549.1.1.5", "sig_algorithm" );
is( length( $decoded2->pubkey ),    140,                    "Pubkey length" );
is( length( $decoded2->signature ), 256,                    "Signature Length" );
is( join( ',', @{ $decoded2->SubjectAltName } ), "rfc822Name=alexander.jung\@allianz.de", 'SubjectAltName parsed' );

$cert = loadcert('t/aj2.cer');
$decoded3 = Crypt::X509->new( cert => $cert );
is( $decoded3->error, undef, 'decode successful' );
is( join( ':', @{ $decoded3->KeyUsage } ), "critical:digitalSignature:keyAgreement", 'KeyUsage Check AuthCert' );

$cert = loadcert('t/allianz_root.cer');
$decoded = Crypt::X509->new( cert => $cert );
is( $decoded->error, undef, 'decode successful' );
is( join( ',', @{ $decoded->authorityCertIssuer } ), "C=DE,O=Allianz Group,CN=Allianz Group Root CA", "authorityCertIssuer" );
is( $decoded->CRLDistributionPoints->[0], "http://rootca.allianz.com/rootca.crl", "CRLDistributionPoints" );
is( $decoded->authority_cn,               "Allianz Group Root CA",                "authority_cn" );
is( $decoded->authority_country,          "DE",                                   "authority_country" );
is( $decoded->authority_state,            undef,                                  "authority_state" );
is( $decoded->authority_locality,         undef,                                  "authority_locality" );
is( $decoded->authority_org,              "Allianz Group",                        "authority_org" );
is( $decoded->authority_email,            undef,                                  "authority_email" );
is( $decoded->pubkey_components()->{modulus}, Math::BigInt::->new('0x00d0a158415c62152e7b342f5881e5bca0842089d583929265af37099d4b4208f149c7084a3eec548fae81823884bbf0f7aee254c44a5a956eafd531b97cb7e9f7e88c9ebfb15b1126cc2edc616ea8b3be3af23a61e8ee0a5ea5af100f0bc7e3f5fcc45acf3f956f3073186fa7e815e853588d02d7942f36680e88c501c70b3d91be3fe96548a352355678c8088d6ac5bda1e9187a05dc3119c68bea1f8ee2acf0a6d261099eeaf10ca8fd380da43eb31010b4015f9e9fc0ab2075fb0b5f56796010cf46760cc73c058a1ec8dcb39e04079025446a2a45a4188bfbb3e299afb01cb5332ee56f72dce6c46fb2f6b5956afb5fece48a6ec6f82313effa057ecd874b'), 'pubkey_components modulus');
is( $decoded->pubkey_components()->{exponent}, Math::BigInt::->new('0x10001'), 'pubkey_components exponent' );

$cert = loadcert('t/new_root_ca.cer');
$decoded = Crypt::X509->new( cert => $cert );
is( $decoded->error, undef, 'decode of new_root_ca.cer successful' );
is( join( ', ', @{ $decoded->BasicConstraints } ), 'critical, cA = 1', 'Basic Constraints' );
is( $decoded->EntrustVersion, 'V7.1:4.0', 'Entrust Version' );
is( $decoded->version_string, 'v3',       'certificate version string' );
%SIA = $decoded->SubjectInfoAccess;
is( $SIA{'1.3.6.1.5.5.7.48.5'}[0], 'uniformResourceIdentifier = http://pki.treas.gov/root_sia.p7c', 'Subject Info Access' );

$cert = loadcert('t/subca_2.cer');
$decoded = Crypt::X509->new( cert => $cert );
is( $decoded->error, undef, 'decode of subca_2.cer successful' );
%CDPs = $decoded->CRLDistributionPoints2;
is( $CDPs{'1'}[0],'Directory Address: CN=CRL1,OU=US Treasury Root CA,OU=Certification Authorities,OU=Department of the Treasury,O=U.S. Government,C=US', 'CRL Distribution Points' );
is( unpack( "H*", $decoded->subject_keyidentifier ), '86595f93caf32da620a4f9595a4a935370e792c9', 'subject key identifier' );

$cert = loadcert('t/telesec_799972029.crt');
$decoded = Crypt::X509->new( cert => $cert );
( $sec, $min, $hour, $mday, $mon, $year,, ) = gmtime( $decoded->not_after );
is( $decoded->not_after, 1111826160, 'not_after got parsed' );
is( $sec,                0,          "generalTime Seconds" );
is( $min,                36,         "generalTime Minutess" );
is( $hour,               8,          "generalTime hours" );
is( $mday,               26,         "generalTime day" );
is( $mon + 1,            3,          "generalTime month" );
is( $year + 1900,        2005,       "generalTime year" );
is( join( ',', @{ $decoded->Issuer } ), 'C=DE,O=Deutsche Telekom AG,nameDistinguisher=1,CN=NKS CA 6:PN', 'Issuer for telesec' );
is( join( ',', @{ $decoded->Subject } ), 'C=DE,nameDistinguisher=2,CN=Schefe, Jan', 'Subject for telesec' );

$cert = loadcert('t/dsacert.der');
$decoded = Crypt::X509->new( cert => $cert );
is( $decoded->error, undef, 'decode of dsacert.der successful' );

#test parser after invalid cert has been loaded
$invalid_cert = Crypt::X509->new( cert => 'invalid' );
ok( $invalid_cert->error, 'got error on invalid data' );
$cert = loadcert('t/verisign.der');
$valid_cert = Crypt::X509->new( cert => $cert );
ok( defined $valid_cert, 'new() returned something' );
is( $valid_cert->error,     undef,      'decode successful' );
is( $valid_cert->not_after, 1848787199, 'not_after got parsed' );

$cert = loadcert('t/pgpextension.der');
$decoded = Crypt::X509->new( cert => $cert );
is( $decoded->error,      undef,    'decode of pgpextension.der successful' );
is( $decoded->SigHashAlg, 'SHA512', 'Detecting SHA512 correctly' );
is( $decoded->PGPExtension, 1292907852, 'creation time matched' );

exit();

sub loadcert {
	my $file = shift;
	open FILE, $file || die "cannot load test certificate" . $file . "\n";
	binmode FILE;    # HELLO Windows, dont fuss with this
	my $holdTerminator = $/;
	undef $/;        # using slurp mode to read the DER-encoded binary certificate
	my $cert = <FILE>;
	$/ = $holdTerminator;
	close FILE;
	return $cert;
}
