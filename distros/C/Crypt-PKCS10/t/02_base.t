# -*- mode: cperl; -*-

# Base tests for Crypt::PKCS10

# This software is copyright (c) 2014 by Gideon Knocke.
# Copyright (c) 2016 Gideon Knocke, Timothe Litt
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
# Terms of the Perl programming language system itself
#
# a) the GNU General Public License as published by the Free
#   Software Foundation; either version 1, or (at your option) any
#   later version, or
# b) the "Artistic License"
#
# See LICENSE for details.
#
use strict;
use warnings;

use Test::More 0.94;

use File::Spec;

# Name of directory where data files are found

my @dirpath = (File::Spec->splitpath( $0 ))[0,1];

my $decoded;

plan  tests => 11;

# Basic functions test requires RSA

# Some useful information for automated testing reports

my $sslver = eval {
    local $SIG{__WARN__} = sub {};

    my $text;
    if( $ENV{AUTOMATED_TESTING} ) {
        $text = qx/openssl version -a 2>&1/;
        return unless( $? == 0 && defined $text &&
                       $text !~ /invalid command/ );

        $text =~ s/(?msi:^WARNING:(?: can't open config file:)?[^\n]*\n)//g;
        return unless( length $text );

        # see makefile_test_ssl for info on 'algorithms'
        # It would be a lot shorter, but too new (as of 2016)
        # to employ.

        my $ciphers = qx/openssl ciphers 2>&1/;
        if( $? == 0 && defined $ciphers &&
            $ciphers !~ /invalid command/ ) {
            $ciphers =~  s/(?msi:^WARNING:(?: can't open config file:)?[^\n]*\n)//g;
            if( length $ciphers ) {
                chomp $ciphers;
                $ciphers = join( ' ', sort split( /:/, $ciphers ) );
                $text .= sprintf( "ciphers:          %s\n", $ciphers );
            }
        }

        require Text::Wrap;

        $text =~ s/^((?:compiler|options|ciphers|algorithms):[ ]+)([^\n]*)\n/
                 $1 . Text::Wrap::wrap( "", ' ' x 20, $2 ) . "\n"/gmsexi;
    } else {
        $text = qx/openssl version 2>&1/;
        return unless( $? == 0 && defined $text &&
                       $text !~ /invalid command/ );
        $text =~ s/(?msi:^WARNING:(?: can't open config file:)?[^\n]*\n)//g;
        return unless( length $text );
    }
    return $text;
};
if( defined $sslver && length $sslver) {
    chomp $sslver;
    $sslver = $ENV{AUTOMATED_TESTING}? "\n$sslver": " / $sslver";
} else {
    $sslver = '';
}
pass( 'configuration' );
diag( sprintf( "Perl %s version %vd%s\n", $^X, $^V, $sslver ) );
$sslver = join( ', ', map { !eval "require $_;"? ( /^.*::(.*)$/, ): () }
                ( qw/Crypt::OpenSSL::DSA Crypt::OpenSSL::RSA/ ) ); # Expose subtest skips
diag( "Skipping $sslver tests: no support\n" ) if( $sslver );
undef $sslver;

subtest 'Basic functions' => sub {
    plan tests => 40;

    use_ok('Crypt::PKCS10') or BAIL_OUT( "Can't load Crypt::PKCS10" );

    # Fixed public API methods

    can_ok( 'Crypt::PKCS10', qw/setAPIversion getAPIversion name2oid oid2name registerOID new error csrRequest subject
                                subjectAltName version pkAlgorithm subjectPublicKey signatureAlgorithm
                                signature attributes certificateTemplate extensions extensionValue
                                extensionPresent subjectPublicKeyParams signatureParams checkSignature/ );

    # Dynamically-generated fixed accessor methods

    can_ok( 'Crypt::PKCS10', qw/commonName organizationalUnitName organizationName
                          emailAddress stateOrProvinceName countryName domainComponent/ );

    is( Crypt::PKCS10->getAPIversion, undef, 'getAPIversion unset' );

    ok( Crypt::PKCS10->setAPIversion(1), 'setAPIversion 1' );

    cmp_ok( Crypt::PKCS10->getAPIversion, '==', 1, 'getAPIversion 1' );

    my $csr = << '-CERT-';
random junk
more stuff
-----BEGIN CERTIFICATE REQUEST-----
MIICzjCCAbYCAQAwgYgxEzARBgoJkiaJk/IsZAEZFgNvcmcxFzAVBgoJkiaJk/Is
ZAEZFgdPcGVuU1NMMRUwEwYKCZImiZPyLGQBGRYFdXNlcnMxIzALBgNVBAMMBHRl
c3QwFAYKCZImiZPyLGQBAQwGMTIzNDU2MRwwGgYJKoZIhv	cNAQkBFg10ZXN0QHRl
c3QuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4EhMEu4ppW+3
LSgp/fKGhZsEmgB9kDASa90enSMZvji0pAsAQW3FSwADQLpYC7HFEeJR4aeB7CE5
xS1B4WIm9gfRxLMCekqVHq3IjpCxAN5WjyZ5AsaUOZ0TkrJ7en8x2EeV5R1oM+5G
Eyv8BJ+flizG9Q5RHxpWIn1H1+PWD4dW2RSo/PVECmflceQQb6bmyxy+bka5Sr7W
LxG95LLPss8zBVhlTn8nzMgrKHCFF6MzajapMItWg8vz3MpJLNVjrjp00tM3Qkpk
R3HM6HBNxH5n7P8jiVh6V+OiGXgTEUpYzs0mAHG/A8l6pLLQvw4fUTECArx97nm6
nohKZSijbwIDAQABoAAwDQYJKoZIhvcNAQELBQADggEBANyLoU6t4AuVLNqs8PSJ
hkB/AYArPSxibAzqQvl3o5w9u1jbAcGJf7cqPUbIESaeRGxMII9jAwaUIW+E7MqZ
FjpgWH5b3xQHVyjknpteOZJnICHmlMHcwqX1uk+ywC3hRTcC/+k+wtnbs0hvCh6c
t17iTm9qI8Tlf4xhHFrsXeCOCmtN3/HSjy3c9dYVB/je5JDesYWiDy1Ssp5D/Fg9
OwC37p57VNLEyCj397q/bdQtd9wkMQKbYTMOC1Wm3Mco9XOvGW/evs20t4xINjbk
xTf+NvadhsWn4CRnKkUEyqOivkjokf9Lg7SBXqaXL1Q2dGbezOa+lMZ67QQUU5Jo
RyYABCGHIzz=
-----END CERTIFICATE REQUEST-----
trailing junk
more junk
-CERT-

    $decoded = eval { Crypt::PKCS10->new( undef, dieOnError => 1, verifySignature => 0 ) };
    like( $@, qr/^\$csr argument to new\(\) is not defined at /, "dieOnError generates exception" ) or BAIL_OUT( Crypt::PKCS10->error );

    $decoded = eval { Crypt::PKCS10->new( undef, verifySignature => 0 ); 1 };
    like( $@, qr/^Value of Crypt::PKCS10->new ignored at /, "new() in void context generates exception" ) or BAIL_OUT( Crypt::PKCS10->error );

    $decoded = Crypt::PKCS10->new( $csr, PEMonly => 1, verifySignature => 0 );

    isnt( $decoded, undef, 'load PEM from variable' ) or BAIL_OUT( Crypt::PKCS10->error );

    isa_ok( $decoded, 'Crypt::PKCS10' ); # Make sure new objects are blessed

    is( $decoded->version, "v1", 'CSR version' );

    is( $decoded->commonName, "test", 'CSR commonName' );

    is( $decoded->emailAddress, 'test@test.com', 'emailAddress' );

    is( $decoded->subjectPublicKey, '3082010a0282010100e0484c12ee29a56fb72d2829fdf286859b049a007' .
	'd9030126bdd1e9d2319be38b4a40b00416dc54b000340ba580bb1c511e251e1a781ec2139c52d41e16226f6' .
	'07d1c4b3027a4a951eadc88e90b100de568f267902c694399d1392b27b7a7f31d84795e51d6833ee46132bf' .
	'c049f9f962cc6f50e511f1a56227d47d7e3d60f8756d914a8fcf5440a67e571e4106fa6e6cb1cbe6e46b94a' .
	'bed62f11bde4b2cfb2cf330558654e7f27ccc82b28708517a3336a36a9308b5683cbf3dcca492cd563ae3a7' .
	'4d2d337424a644771cce8704dc47e67ecff2389587a57e3a2197813114a58cecd260071bf03c97aa4b2d0bf' .
	'0e1f51310202bc7dee79ba9e884a6528a36f0203010001', 'hex subjectPublicKey' );

    is( $decoded->subjectPublicKey(1), << '_KEYPEM_', 'PEM subjectPublicKey' );
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4EhMEu4ppW+3LSgp/fKG
hZsEmgB9kDASa90enSMZvji0pAsAQW3FSwADQLpYC7HFEeJR4aeB7CE5xS1B4WIm
9gfRxLMCekqVHq3IjpCxAN5WjyZ5AsaUOZ0TkrJ7en8x2EeV5R1oM+5GEyv8BJ+f
lizG9Q5RHxpWIn1H1+PWD4dW2RSo/PVECmflceQQb6bmyxy+bka5Sr7WLxG95LLP
ss8zBVhlTn8nzMgrKHCFF6MzajapMItWg8vz3MpJLNVjrjp00tM3QkpkR3HM6HBN
xH5n7P8jiVh6V+OiGXgTEUpYzs0mAHG/A8l6pLLQvw4fUTECArx97nm6nohKZSij
bwIDAQAB
-----END PUBLIC KEY-----
_KEYPEM_

    is_deeply( $decoded->subjectPublicKeyParams,
               {keytype => 'RSA',
                keylen => 2048,
                modulus => 'e0484c12ee29a56fb72d2829fdf286859b049a007d9030126bdd1e9d2319be38b4a40b00416dc54b000340ba580bb1c511e251e1a781ec2139c52d41e16226f607d1c4b3027a4a951eadc88e90b100de568f267902c694399d1392b27b7a7f31d84795e51d6833ee46132bfc049f9f962cc6f50e511f1a56227d47d7e3d60f8756d914a8fcf5440a67e571e4106fa6e6cb1cbe6e46b94abed62f11bde4b2cfb2cf330558654e7f27ccc82b28708517a3336a36a9308b5683cbf3dcca492cd563ae3a74d2d337424a644771cce8704dc47e67ecff2389587a57e3a2197813114a58cecd260071bf03c97aa4b2d0bf0e1f51310202bc7dee79ba9e884a6528a36f',
                publicExponent => '10001',
               }, 'subjectPublicKeyParams(RSA)' );

    is( $decoded->signature, 'dc8ba14eade00b952cdaacf0f48986407f01802b3d2c626c0cea42f977a39c3dbb5' .
	'8db01c1897fb72a3d46c811269e446c4c208f63030694216f84ecca99163a60587e5bdf14075728e49e9b5e3' .
	'992672021e694c1dcc2a5f5ba4fb2c02de1453702ffe93ec2d9dbb3486f0a1e9cb75ee24e6f6a23c4e57f8c6' .
	'11c5aec5de08e0a6b4ddff1d28f2ddcf5d61507f8dee490deb185a20f2d52b29e43fc583d3b00b7ee9e7b54d' .
	'2c4c828f7f7babf6dd42d77dc2431029b61330e0b55a6dcc728f573af196fdebecdb4b78c483636e4c537fe3' .
	'6f69d86c5a7e024672a4504caa3a2be48e891ff4b83b4815ea6972f54367466decce6be94c67aed04145392684726',
	'signature' );

    is( unpack( "H*", $decoded->certificationRequest ),
        '308201b602010030818831133011060a0992268993f22c64011916036f726731173015060a0992268993f22c' .
        '64011916074f70656e53534c31153013060a0992268993f22c640119160575736572733123300b0603550403' .
        '0c04746573743014060a0992268993f22c6401010c06313233343536311c301a06092a864886f70d01090116' .
        '0d7465737440746573742e636f6d30820122300d06092a864886f70d01010105000382010f003082010a0282' .
        '010100e0484c12ee29a56fb72d2829fdf286859b049a007d9030126bdd1e9d2319be38b4a40b00416dc54b00' .
        '0340ba580bb1c511e251e1a781ec2139c52d41e16226f607d1c4b3027a4a951eadc88e90b100de568f267902' .
        'c694399d1392b27b7a7f31d84795e51d6833ee46132bfc049f9f962cc6f50e511f1a56227d47d7e3d60f8756' .
        'd914a8fcf5440a67e571e4106fa6e6cb1cbe6e46b94abed62f11bde4b2cfb2cf330558654e7f27ccc82b2870' .
        '8517a3336a36a9308b5683cbf3dcca492cd563ae3a74d2d337424a644771cce8704dc47e67ecff2389587a57' .
        'e3a2197813114a58cecd260071bf03c97aa4b2d0bf0e1f51310202bc7dee79ba9e884a6528a36f0203010001a000',
        'certificationRequest' );

    is( scalar $decoded->subject, '/DC=org/DC=OpenSSL/DC=users/CN=test/UID=123456/emailAddress=test@test.com',
	'subject()' );

    is( scalar $decoded->userID, '123456', 'userID accessor autoloaded' );

    # Note that this is the input, but with junk removed.

    my $extcsr = << '~~~';
-----BEGIN CERTIFICATE REQUEST-----
MIICzjCCAbYCAQAwgYgxEzARBgoJkiaJk/IsZAEZFgNvcmcxFzAVBgoJkiaJk/Is
ZAEZFgdPcGVuU1NMMRUwEwYKCZImiZPyLGQBGRYFdXNlcnMxIzALBgNVBAMMBHRl
c3QwFAYKCZImiZPyLGQBAQwGMTIzNDU2MRwwGgYJKoZIhvcNAQkBFg10ZXN0QHRl
c3QuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4EhMEu4ppW+3
LSgp/fKGhZsEmgB9kDASa90enSMZvji0pAsAQW3FSwADQLpYC7HFEeJR4aeB7CE5
xS1B4WIm9gfRxLMCekqVHq3IjpCxAN5WjyZ5AsaUOZ0TkrJ7en8x2EeV5R1oM+5G
Eyv8BJ+flizG9Q5RHxpWIn1H1+PWD4dW2RSo/PVECmflceQQb6bmyxy+bka5Sr7W
LxG95LLPss8zBVhlTn8nzMgrKHCFF6MzajapMItWg8vz3MpJLNVjrjp00tM3Qkpk
R3HM6HBNxH5n7P8jiVh6V+OiGXgTEUpYzs0mAHG/A8l6pLLQvw4fUTECArx97nm6
nohKZSijbwIDAQABoAAwDQYJKoZIhvcNAQELBQADggEBANyLoU6t4AuVLNqs8PSJ
hkB/AYArPSxibAzqQvl3o5w9u1jbAcGJf7cqPUbIESaeRGxMII9jAwaUIW+E7MqZ
FjpgWH5b3xQHVyjknpteOZJnICHmlMHcwqX1uk+ywC3hRTcC/+k+wtnbs0hvCh6c
t17iTm9qI8Tlf4xhHFrsXeCOCmtN3/HSjy3c9dYVB/je5JDesYWiDy1Ssp5D/Fg9
OwC37p57VNLEyCj397q/bdQtd9wkMQKbYTMOC1Wm3Mco9XOvGW/evs20t4xINjbk
xTf+NvadhsWn4CRnKkUEyqOivkjokf9Lg7SBXqaXL1Q2dGbezOa+lMZ67QQUU5Jo
RyY=
-----END CERTIFICATE REQUEST-----
~~~

    my $extder = "0\202\2\3160\202\1\266\2\1\0000\201\2101\0230\21\6\n\t\222&\211" .
      "\223\362,d\1\31\26\3org1\0270\25\6\n\t\222&\211\223\362,d\1\31\26\aOpenSSL1" .
      "\0250\23\6\n\t\222&\211\223\362,d\1\31\26\5users1#0\13\6\3U\4\3\f\4test0\24" .
      "\6\n\t\222&\211\223\362,d\1\1\f\0061234561\0340\32\6\t*\206H\206\367\r\1\t\1" .
      "\26\rtest\@test.com0\202\1\"0\r\6\t*\206H\206\367\r\1\1\1\5\0\3\202\1\17\0000" .
      "\202\1\n\2\202\1\1\0\340HL\22\356)\245o\267-()\375\362\206\205\233\4\232\0}" .
      "\2200\22k\335\36\235#\31\2768\264\244\13\0Am\305K\0\3\@\272X\13\261\305\21" .
      "\342Q\341\247\201\354!9\305-A\341b&\366\a\321\304\263\2zJ\225\36\255\310\216" .
      "\220\261\0\336V\217&y\2\306\2249\235\23\222\262{z\1771\330G\225\345\35h3\356F" .
      "\23+\374\4\237\237\226,\306\365\16Q\37\32V\"}G\327\343\326\17\207V\331\24\250" .
      "\374\365D\ng\345q\344\20o\246\346\313\34\276nF\271J\276\326/\21\275\344\262" .
      "\317\262\3173\5XeN\177'\314\310+(p\205\27\2433j6\2510\213V\203\313\363\334\312" .
      "I,\325c\256:t\322\3237BJdGq\314\350pM\304~g\354\377#\211XzW\343\242\31x\23\21JX" .
      "\316\315&\0q\277\3\311z\244\262\320\277\16\37Q1\2\2\274}\356y\272\236\210Je(\243o" .
      "\2\3\1\0\1\240\0000\r\6\t*\206H\206\367\r\1\1\13\5\0\3\202\1\1\0\334\213\241N\255" .
      "\340\13\225,\332\254\360\364\211\206\@\177\1\200+=,bl\f\352B\371w\243\234=\273X" .
      "\333\1\301\211\177\267*=F\310\21&\236DlL \217c\3\6\224!o\204\354\312\231\26:`X~[" .
      "\337\24\aW(\344\236\233^9\222g !\346\224\301\334\302\245\365\272O\262\300-\341E7\2" .
      "\377\351>\302\331\333\263Ho\n\36\234\267^\342Noj#\304\345\177\214a\34Z\354]\340\216" .
      "\nkM\337\361\322\217-\334\365\326\25\a\370\336\344\220\336\261\205\242\17-R\262" .
      "\236C\374X=;\0\267\356\236{T\322\304\310(\367\367\272\277m\324-w\334\$1\2\233a3\16" .
      "\13U\246\334\307(\365s\257\31o\336\276\315\264\267\214H66\344\3057\3766\366\235\206" .
      "\305\247\340\$g*E\4\312\243\242\276H\350\221\377K\203\264\201^\246\227/T6tf\336\314" .
      "\346\276\224\306z\355\4\24S\222hG&";

    is( $decoded->csrRequest(1), $extcsr, 'extracted PEM' );

    ok( $decoded->csrRequest eq $extder, 'extracted DER' );

    isnt( $decoded, undef, 'load PEM from variable' ) or BAIL_OUT( Crypt::PKCS10->error );

    #is( $decoded->pkAlgorithm, 'RSA encryption', 'correct encryption algorithm' );
    is( $decoded->pkAlgorithm, 'rsaEncryption', 'encryption algorithm' );

    #is( $decoded->signatureAlgorithm, 'SHA-256 with RSA encryption', 'correct signature algorithm' );
    is( $decoded->signatureAlgorithm, 'sha256WithRSAEncryption', 'signature algorithm' );

    is( $decoded->signatureParams, undef, 'signature parameters' ); # RSA is NULL

    is( $decoded->signature(2), undef, 'signature decoding' );

  SKIP: {
        skip( "Crypt::OpenSSL::RSA not installed", 1 ) unless( eval { require Crypt::OpenSSL::RSA; } );

        ok( $decoded->checkSignature, 'verify RSA CSR signature' );
    }

    my $file = File::Spec->catpath( @dirpath, 'csr1.pem' );

    $decoded = Crypt::PKCS10->new( $file, readFile => 1, verifySignature => 0 );

    isnt( $decoded, undef, 'load PEM from filename' ) or BAIL_OUT( Crypt::PKCS10->error );

    my $der = $decoded->csrRequest;

    $file = File::Spec->catpath( @dirpath, 'csr1.cer' ); # N.B. Padding added to test removal

    if( open( my $csr, '<', $file ) ) {
	$decoded = Crypt::PKCS10->new( $csr, { verifySignature => 0, acceptPEM => 0, binaryMode => 1 }, escapeStrings => 0 );
    } else {
	BAIL_OUT( "$file: $!\n" );
    }

    isnt( $decoded, undef, 'load DER from file handle' ) or BAIL_OUT( Crypt::PKCS10->error );

    ok( $der eq $decoded->csrRequest, "DER from file matches DER from PEM" );

    subtest "subject name component access" => sub {
	plan tests => 9;

	is( join( ',',  $decoded->countryName ),            'AU',                       '/C' );
	is( join( ',',  $decoded->stateOrProvinceName ),    'Some-State',               '/ST' );
	is( join( ',',  $decoded->localityName ),           'my city',                  '/L' );
	is( join( ',',  $decoded->organizationName ),       'Internet Widgits Pty Ltd', '/O' );
	is( join( ',',  $decoded->organizationalUnitName ), 'Big org,Smaller org',      '/OU/OU' );
	is( join( ',',  $decoded->commonName ),             'My Name',                  '/CN' );
	is( join( ',',  $decoded->emailAddress ),           'none@no-email.com',        '/emailAddress' );
	is( join( ',',  $decoded->domainComponent ),        'domainComponent',          '/DC' );

	is_deeply( [ $decoded->subject ],
		   [
		    'countryName',
		    [
		     'AU'
		    ],
		    'stateOrProvinceName',
		    [
		     'Some-State'
		    ],
		    'localityName',
		    [
		     'my city'
		    ],
		    'organizationName',
		    [
		     'Internet Widgits Pty Ltd'
		    ],
		    'organizationalUnitName',
		    [
		     'Big org'
		    ],
		    'organizationalUnitName',
		    [
		     'Smaller org'
		    ],
		    'commonName',
		    [
		     'My Name'
		    ],
		    'emailAddress',
		    [
		     'none@no-email.com'
		    ],
		    'domainComponent',
		    [
		     'domainComponent'
		    ]
		   ], "subject name component list" );
    };

    $file = File::Spec->catpath( @dirpath, 'csr3.cer' );

    my $bad;

  SKIP: {
        skip( "Crypt::OpenSSL::RSA is not installed", 5 ) unless( eval { require Crypt::OpenSSL::RSA } );

        if( open( my $csr, '<', $file ) ) {
            $bad = Crypt::PKCS10->new( $csr, acceptPEM => 0, escapeStrings => 0 );
        } else {
            BAIL_OUT( "$file: $!\n" );
        }

        is( $bad, undef, 'bad signature rejected' ) or BAIL_OUT( Crypt::PKCS10->error );

        $bad = Crypt::PKCS10->new( $file, readFile =>1, acceptPEM => 0, escapeStrings => 0,
                                   verifySignature => 0 );
        isnt( $bad, undef, 'bad signature loaded' ) or BAIL_OUT( Crypt::PKCS10->error );

        ok( !$bad->checkSignature, 'checkSignature returns false' );
        ok( defined Crypt::PKCS10->error, 'checkSignature sets error string' );
        cmp_ok( Crypt::PKCS10->error, 'eq', $bad->error, 'class and instance error strings match' );
    }

    $file = File::Spec->catpath( @dirpath, 'csr8.pem' );

    is( Crypt::PKCS10->new( $file, readFile => 1, verifySignature => 0 ), undef, 'reject invalid base64' );

    $bad = Crypt::PKCS10->new( $file, readFile => 1, verifySignature => 0, ignoreNonBase64 => 1 );

    isnt( $bad, undef, 'accept invalid base64' ) or BAIL_OUT( Crypt::PKCS10->error );

    my $good = << 'GOOD';
-----BEGIN CERTIFICATE REQUEST-----
MIICuzCCAiQCAQAwIzEQMA4GA1UECgwHVGVzdE9yZzEPMA0GA1UEAwwGVGVzdENO
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC95h0aRkhNcqBrktxNXzOGgurp
/vkUDFKNda/ruTMeOlPvXRGIS+kWm8tbahrEXp47bOu1usA7k2EWLQyqm5sdjwXt
VyLos5Nw18hG2acHqbQSV8ZtYPR8xwpXzZYdFghwVo/Clu3jD1c5Cm0oofZSD/5c
9JXmXgBWdySjlkxfRwIDAQABoIIBVjAaBgorBgEEAYI3DQIDMQwWCjYuMS43NjAx
LjIwMwYJKwYBBAGCNxUUMSYwJAIBCQwGU2NyZWFtDA5TY3JlYW1cdGltb3RoZQwH
Y2VydHJlcTBCBgorBgEEAYI3DQIBMTQwMh4mAEMAZQByAHQAaQBmAGkAYwBhAHQA
ZQBUAGUAbQBwAGwAYQB0AGUeCABVAHMAZQByMFcGCSqGSIb3DQEJDjFKMEgwFwYJ
KwYBBAGCNxQCBAoeCABVAHMAZQByMB0GA1UdDgQWBBTQ6yfAQdFGh07DGiOC14E3
p9NQIDAOBgNVHQ8BAf8EBAMCB4AwZgYKKwYBBAGCNw0CAjFYMFYCAQIeTgBNAGkA
YwByAG8AcwBvAGYAdAAgAFMAdAByAG8AbgBnACAAQwByAHkAcAB0AG8AZwByAGEA
cABoAGkAYwAgAFAAcgBvAHYAaQBkAGUAcgMBADANBgkqhkiG9w0BAQUFAAOBgQBa
KlxVOri+lsnuN+mj12I3zFeWcFMigq87N8VG+R2bfiq0voNCYNbvteEdPQJm99EA
9tEF1Lm3u9U8cmTZAvUNO9A1NlPX8e660ra6WQN2IKfDZp4XX5qisg3tus7WTfG7
aLNx7HGTQt7c2f7AlhuoQJZsCpGrcxIFmsY3yB/bTw==
-----END CERTIFICATE REQUEST-----
GOOD
    cmp_ok( $bad->csrRequest(1), 'eq', $good, 'correct invalid base64' );
};

subtest 'attribute functions' => sub {
    plan tests => 7;

    is_deeply( [ $decoded->attributes ], [qw/challengePassword unstructuredName/],
	       'attributes list is correct' );
    is( scalar $decoded->attributes( 'missing' ), undef, 'missing attribute ' );
    is( scalar $decoded->attributes( '1.2.840.113549.1.9.7' ), 'Secret',
	'challengePassword string by OID' );
    is( scalar $decoded->attributes( 'challengePassword' ), 'Secret',
	'challengePassword string' );
    is_deeply( [ $decoded->attributes( 'challengePassword' ) ], [ 'Secret' ],
	       'challengePassword array' );

    is( scalar $decoded->attributes( 'unstructuredName' ), 'MyCoFoCo',
	'unstructuredName string' );
    is_deeply( [ $decoded->attributes( 'unstructuredName' ) ], [ 'MyCoFoCo' ],
	       'unstructuredName array' );
};

subtest "basic extension functions" => sub {
    plan tests => 18;

    is_deeply( [ $decoded->extensions ],
	       [ qw/basicConstraints keyUsage extKeyUsage subjectAltName
                    subjectKeyIdentifier certificatePolicies/ ],
	       'extensions list is correct' );

    is( $decoded->extensionPresent( '-- I surely dont exist-' ), undef, 'extensionPresent undef' );
    is( $decoded->extensionPresent( '2.5.29.14' ), 1, 'extensionPresent by OID' ); # subjectKeyIdentifier
    is( $decoded->extensionPresent( 'basicConstraints' ), 2, 'extension present critical ' );

    is( $decoded->extensionValue( 'basicConstraints', 1 ), 'CA:TRUE',
	'basicConstraints string' );
    is( $decoded->extensionValue( '2.5.29.19', 1 ), 'CA:TRUE',
	'basicConstraints string by OID' );
    is_deeply( $decoded->extensionValue( 'basicConstraints' ), { CA => 'TRUE' },
	       'basicConstraints hash' );


    is( $decoded->extensionValue( 'keyUsage', 1 ),
	    'keyEncipherment,nonRepudiation,digitalSignature', 'keyUsage string' );
    ok( ref $decoded->extensionValue('KeyUsage') eq 'ARRAY', 'KeyUsage is an arrayref' );

    is_deeply( $decoded->extensionValue( 'keyUsage'), [
                                                       'keyEncipherment',
                                                       'nonRepudiation',
                                                       'digitalSignature',
                                                      ], 'keyUsage array' );

    is( $decoded->extensionValue( 'extKeyUsage', 1 ),
'emailProtection,serverAuth,clientAuth,codeSigning,emailProtection,timeStamping,OCSPSigning',
        'extKeyUsage string' );
    is_deeply( $decoded->extensionValue( 'extKeyUsage'), [
                                                          'emailProtection',
                                                          'serverAuth',
                                                          'clientAuth',
                                                          'codeSigning',
                                                          'emailProtection',
                                                          'timeStamping',
                                                          'OCSPSigning',
                                                         ], 'extKeyUsage array' );

    is( $decoded->extensionValue( 'subjectKeyIdentifier', 1 ), '0012459a',
        'subjectKeyIdentifier string' );

    is( $decoded->extensionValue( 'certificatePolicies', 1 ),
'(policyIdentifier=postOfficeBox,policyQualifier=((policyQualifierId=CPS,qualifier=http://there.example.net),'.
'(policyQualifierId=CPS,qualifier=http://here.example.net),(policyQualifierId=userNotice,'.
'qualifier=(explicitText="Trust but verify",userNotice=(noticeNumbers=(8,11),organization="Suspicious minds"))),'.
'(policyQualifierId=userNotice,qualifier=(explicitText="Trust but verify",userNotice=(noticeNumbers=(8,11),'.
'organization="Suspicious minds"))))),policyIdentifier=1.5.88.103',
        'certificatePolicies string' );
    is_deeply( $decoded->extensionValue( 'certificatePolicies' ),
            [
	     {
	      'policyIdentifier' => 'postOfficeBox',
	      'policyQualifier' => [
				    {
				     'policyQualifierId' => 'CPS',
				     'qualifier' => 'http://there.example.net'
				    },
				    {
				     'policyQualifierId' => 'CPS',
				     'qualifier' => 'http://here.example.net'
				    },
				    {
				     'policyQualifierId' => 'userNotice',
				     'qualifier' => {
						     'explicitText' => 'Trust but verify',
						     'userNotice' => {
								      'noticeNumbers' => [
											  8,
											  11
											 ],
								      'organization' => 'Suspicious minds'
								     }
						    }
				    },
				    {
				     'policyQualifierId' => 'userNotice',
				     'qualifier' => {
						     'explicitText' => 'Trust but verify',
						     'userNotice' => {
								      'noticeNumbers' => [
											  8,
											  11
											 ],
								      'organization' => 'Suspicious minds'
								     }
						    }
				    }
				   ]
	     },
	     {
	      'policyIdentifier' => '1.5.88.103'
	     }
	    ],
		   'certificatePolicies array' );

    is( $decoded->certificateTemplate, undef, 'certificateTemplate absent' );

    is( $decoded->extensionValue('foo'), undef, 'extensionValue when extension absent' );

    is( $decoded->extensionValue('subjectAltName', 1),
        'rfc822Name=noway@none.com,uniformResourceIdentifier=htt' .
        'ps://fred.example.net,rfc822Name=someday@nowhere.exampl' .
        'e.com,dNSName=www.example.net,dNSName=www.example.com,d' .
        'NSName=example.net,dNSName=example.com,iPAddress=10.2.3' .
        '.4,iPAddress=2001:0DB8:0741:0000:0000:0000:0000:0000', 'subjectAltName' );
};

subtest "subjectAltname" => sub {
    plan tests => 5;

    my $altname = $decoded->extensionValue('subjectAltName');

    my $correct =  [
		    {
		     'rfc822Name' => 'noway@none.com'
		    },
		    {
		     'uniformResourceIdentifier' => 'https://fred.example.net'
		    },
		    {
		     'rfc822Name' => 'someday@nowhere.example.com'
		    },
		    {
		     'dNSName' => 'www.example.net'
		    },
		    {
		     'dNSName' => 'www.example.com'
		    },
		    {
		     'dNSName' => 'example.net'
		    },
		    {
		     'dNSName' => 'example.com'
		    },
		    {
		     'iPAddress' => '10.2.3.4'
		    },
		    {
		     'iPAddress' => '2001:0DB8:0741:0000:0000:0000:0000:0000'
		    }
		   ];
    is_deeply( $correct, $altname, 'structure returned as extension' );

    is( $decoded->subjectAltName, 'rfc822Name:noway@none.com,' .
	'uniformResourceIdentifier:https://fred.example.net,rfc822Name:someday@nowhere.example.com,' .
	'dNSName:www.example.net,dNSName:www.example.com,dNSName:example.net,dNSName:example.com,' .
	'iPAddress:10.2.3.4,iPAddress:2001:0DB8:0741:0000:0000:0000:0000:0000',
	"subjectAltName returns string in scalar context" );

    is( join( ',', sort $decoded->subjectAltName ), 'dNSName,iPAddress,rfc822Name,uniformResourceIdentifier',
	'component list' );

    is( join( ',', $decoded->subjectAltName( 'iPAddress' )),
	'10.2.3.4,2001:0DB8:0741:0000:0000:0000:0000:0000', 'IP address list selection' );

    is( $decoded->subjectAltName( 'iPAddress' ), '10.2.3.4', 'extraction of first IP address' );
};

subtest 'oid mapping' => sub {
    plan tests => 6;

    is( Crypt::PKCS10->name2oid( 'houseIdentifier' ), '2.5.4.51', 'name2oid main table' );
    is( Crypt::PKCS10->name2oid( 'timeStamping' ), '1.3.6.1.5.5.7.3.8', 'name2oid extKeyUsages' );
    is( Crypt::PKCS10->name2oid( '-- I surely dont exist-' ), undef, 'name2oid returns undef if unknown' );

    is( Crypt::PKCS10->oid2name( '2.5.4.51' ), 'houseIdentifier', 'oid2name main table' );
    is( Crypt::PKCS10->oid2name( '1.3.6.1.5.5.7.3.8' ), 'timeStamping', 'oid2name extKeyUsages' );
    is( Crypt::PKCS10->oid2name( '0' ), '0', 'oid2name returns oid if not registered' );

};

subtest 'oid registration' => sub {
    plan tests => 14;

    ok( !Crypt::PKCS10->registerOID( '1.3.6.1.4.1.25043.0' ), 'OID is not registered' );
    ok( Crypt::PKCS10->registerOID( '2.5.4.51' ), 'OID is registered' );
    ok( Crypt::PKCS10->registerOID( '1.3.6.1.5.5.7.3.1' ), 'KeyUsage OID registered' );
    ok( Crypt::PKCS10->registerOID( '1.3.6.1.4.1.25043.0', 'SampleOID' ), 'Register longform OID' );
    is( Crypt::PKCS10->name2oid( 'SampleOID' ),  '1.3.6.1.4.1.25043.0', 'Find by name' );
    is( Crypt::PKCS10->oid2name( '1.3.6.1.4.1.25043.0' ), 'SampleOID', 'Find by OID' );

    ok( Crypt::PKCS10->registerOID( '1.2.840.113549.1.9.1', undef, 'e' ), 'Register /E for emailAddress' );
    cmp_ok( scalar $decoded->subject, 'eq', '/C=AU/ST=Some-State/L=my city/O=Internet Widgits Pty Ltd/OU=Big org/OU=Smaller org/CN=My Name/E=none@no-email.com/DC=domainComponent', 'Short name for /emailAddress' );

    eval{ Crypt::PKCS10->registerOID( '2.5.4.6',  undef, 'C' ) };
    like( $@, qr/^C already registered/, 'Register duplicate shortname' );

    eval{ Crypt::PKCS10->registerOID( 'A',  'name' ) };
    like( $@, qr/^Invalid OID A/, 'Register invalid OID' );

    eval{ Crypt::PKCS10->registerOID( '2.5.4.6',  'emailAddress', 'C' ) };
    like( $@, qr/^2.5.4.6 already registered/, 'Register duplicate oid' );

    eval{ Crypt::PKCS10->registerOID( '1.3.6.1.4.1.25043.0.1',  'emailAddress', 'C' ) };
    like( $@, qr/^emailAddress already registered/, 'Register duplicate longname' );

    eval{ Crypt::PKCS10->registerOID( '1.3.6.1.4.1.25043.0.1',  undef, 'Z' ) };
    like( $@, qr/^1.3.6.1.4.1.25043.0.1 not registered/, 'Register shortname to unassigned OID' );

    eval{ Crypt::PKCS10->registerOID( undef ) };
    like( $@, qr/^Not enough arguments/, 'Minimum arguments' );
};

subtest 'Microsoft extensions' => sub {
    plan tests => 10;

    my $file = File::Spec->catpath( @dirpath, 'csr2.pem' );

    if( open( my $csr, '<', $file ) ) {
	$decoded = Crypt::PKCS10->new( $csr, escapeStrings => 1, verifySignature => 0 );
    } else {
	BAIL_OUT( "$file: $!\n" );
    }

    isnt( $decoded, undef, 'load PEM from file handle' ) or BAIL_OUT( Crypt::PKCS10->error );

    is( scalar $decoded->subject, '/O=TestOrg/CN=TestCN', 'subject' );
    is_deeply( [ $decoded->attributes ],
	       [
		'ClientInformation',
		'ENROLLMENT_CSP_PROVIDER',
		'ENROLLMENT_NAME_VALUE_PAIR',
		'OS_Version'
	       ], 'attributes list' );

    is( scalar $decoded->attributes( 'ENROLLMENT_CSP_PROVIDER' ),
	'cspName="Microsoft Strong Cryptographic Provider",keySpec=2,signature=("",0)',
	'ENROLLMENT_CSP_PROVIDER string ' );
    is_deeply( $decoded->attributes( 'ENROLLMENT_CSP_PROVIDER' ),
	       {
		'cspName' => 'Microsoft Strong Cryptographic Provider',
		'keySpec' => 2,
		'signature' => [
				'',
				0
			       ]
	       }, 'ENROLLMENT_CSP_PROVIDER hash' );

    is( scalar $decoded->attributes('ENROLLMENT_NAME_VALUE_PAIR'),
	'name=CertificateTemplate,value=User', 'ENROLLMENT_NAME_VALUE_PAIR string' );
    is_deeply( $decoded->attributes('ENROLLMENT_NAME_VALUE_PAIR'),
	       {
		'name' => 'CertificateTemplate',
		'value' => 'User'
	       }, 'ENROLLMENT_NAME_VALUE_PAIR hash' );

    is( scalar $decoded->attributes('ClientInformation'),
	'MachineName=Scream,ProcessName=certreq,UserName="Scream\\\\timothe",clientId=9',
	'ClientInformation string' );
    is_deeply( $decoded->attributes('ClientInformation'),
	       {
		'MachineName' => 'Scream',
		'ProcessName' => 'certreq',
		'UserName' => 'Scream\\timothe',
		'clientId' => 9
	       }, 'ClientInformation hash' );

    is( scalar $decoded->attributes( 'OS_Version' ), '6.1.7601.2', 'OS_Version' );
};

subtest 'stringify object' => sub {
    plan tests => 9;

    my $string = eval {
	local $SIG{__WARN__} = sub { die $_[0] };

	return "$decoded";
    };

    cmp_ok( $@, 'eq', '', 'no exception' );

    isnt( $string, undef, 'returns something' );

    cmp_ok( length $string, '>=', 2800, 'approximate result length' ) or
      diag( sprintf( "actual length %u, value:\n%s\n", length $string, $string ) );

    # Perl 5.8.8 bug 39185: sometimes modifiers outside a qr don't work, but do when cloistered.
    # Note that some versions of 5.8.8 have this fixed, some don't.

    like( $string, qr'(?ms:^Subject\s*: /O=TestOrg/CN=TestCN\n)', 'string includes subject' );
    like( $string, qr'(?ms:^publicExponent\s*: 10001)', 'string includes RSA public key' );
    like( $string, qr'(?ms:^-----BEGIN PUBLIC KEY-----$)', 'string includes public key PEM' );
    like( $string, qr'(?ms:^-----END PUBLIC KEY-----$)', 'string closes public key PEM' );
    like( $string, qr'(?ms:^-----BEGIN CERTIFICATE REQUEST-----$)', 'string includes CSR PEM' );
    like( $string, qr'(?ms:^-----END CERTIFICATE REQUEST-----$)', 'string closes CSR PEM' );
};

subtest 'DSA requests' => sub {
    plan tests => 5;

    $decoded = Crypt::PKCS10->new( File::Spec->catpath( @dirpath, 'csr5.pem' ),
                                   verifySignature => 0,
                                   readFile =>1, escapeStrings => 1 );

    isnt( $decoded, undef, 'load PEM from filename' ) or BAIL_OUT( Crypt::PKCS10->error );

    is( $decoded->signatureAlgorithm, 'dsaWithSha256', 'DSA signature' );

    is_deeply( $decoded->subjectPublicKeyParams,
               {keytype => 'DSA',
                keylen => 1024,
                Q => 'b2a130635bfe19dbb3e49d8f5c4bae8266126019',
                P => 'eb3ac7a7928f0a2ab9ef61288cfde11c13e932d3853803daeb2559e8a91abc9dc48577195a471026ef27741f24e60d93a42506f16cd8bd5aebdbf519b5baa3e6470484c3c3790ffc9b5617fbd38545cd07ff60da7846383c848f0ab447ac7ed5dcd35132d882e03269f3694330d41292d92e4472429ffa0e2514ec35ea96ee2d',
                G => 'd2a82fb32f303aab7c554c91096d233cd3e87b2c9e202172a5206c7a228a39195504fcf6266748ea1a212cef6b9632bdc2012a766875c93334f7dacc24fef6ed11c185af502b236637bfdb3f8fab1de2b4bc26b45d5bb6171b8c169eca77977b5b4b9c9ca7df4052c7717bd885db9436d09829659e886de35173da53a16b78d7',
               }, 'subjectPublicKeyParams(DSA)' );

    is( $decoded->signature(2), undef, 'signature decoding' );
  SKIP: {
        skip( "Crypt::OpenSSL::DSA is not installed", 1 ) unless( eval { require Crypt::OpenSSL::DSA; } );

        ok( $decoded->checkSignature, "verify DSA signature" );
    }
};

subtest 'API v0' => sub {
    plan tests => 6;

    Crypt::PKCS10->setAPIversion( 0 );
    my $csr = eval { Crypt::PKCS10->new( '', PEMonly => 1 ); };
    is( $csr, undef, 'new is undef' );
    ok( $@, 'failure throws exception' );
    my $err = Crypt::PKCS10->error;
    chomp $err;
    like( $@, qr/(?ms:^$err\s+at .*02_base\.t line \d+.)/, 'failure returns error string' );

    my $file = File::Spec->catpath( @dirpath, 'csr3.cer' );
    $csr = eval { Crypt::PKCS10->new( $file, readFile => 1, acceptPEM => 0 ); };
    isnt( $csr, undef, 'doesn\'t verify signature' );
    eval { $csr->subjectPublicKeyParams };
    ok( $@, 'subjectPublicKeyParams throws exception' );
    ok( ref $csr->extensionValue('KeyUsage') eq '', 'KeyUsage is a scalar' );

    # More API v0 tests needed
};


1;

