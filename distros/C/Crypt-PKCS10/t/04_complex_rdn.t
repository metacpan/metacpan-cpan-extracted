#!/usr/bin/perl

use strict;
use warnings;

use Test::More 0.94;

plan tests => 2;
use Crypt::PKCS10;

my $data = "-----BEGIN CERTIFICATE REQUEST-----
MIIC2zCCAcMCAQAwgZUxCzAJBgNVBAYTAkRFMRAwDgYDVQQKDAdPcGVuUEtJMRYw
FAYDVQQLDA1CcmFuY2grT2ZmaWNlMQswCQYDVQQLDAJJVDEpMA8GA1UEAwwISm9o
biBEb2UwFgYKCZImiZPyLGQBAQwIam9obi5kb2UxJDAiBgkqhkiG9w0BCQEWFWpv
aG4uZG9lQG9wZW54cGtpLm9yZzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
ggEBALrJW2JP/vytMG1VI4tl3zfhsybPEmxy43yCgLC0SGdObzD3LrwIS1cITMb2
RExBpcql/Zxza2zCMsbqE+PzPP1zx6aEC+c6vFa+m3ohN7G7HImmFevF22Yf3Q9I
yxbSjeP2FSh3AvX9XqbMy/hdOaV2UALi7piz3llKJrEPqfKHM7iJJTH3bFtFMBNt
miTuOcaGdmev1Lmq5CdLfyOr19NMj3/tX695Ok7zR8K36l9e/uIQBhKHzNtn5nVL
4pcPCDnAeqw868reHhFs0V8wqEo3bFsEGe/DmCC1sy8ZiNhE6RK7lcf3bgnC2cxO
izpCtqxnEFF6CSnwy3Rsj4j5I8kCAwEAAaAAMA0GCSqGSIb3DQEBCwUAA4IBAQAs
InsCd1P8yTX6G+6KwQqXgXuQqo51vuvUOOrpNIiYRZDyhoJyQBcD5gP1usNUgL/E
W+ulGcjGrHAXNh+4TO9/eFgQbzx+wBfTaUcPLwVxiEfuDLqaQPoxe6rT/TZE2ccO
qE20zqZIXYu1MhxJd185DTDx2zD4zeHRer+xIpt8xDlJ5WKDeynLxtP8zCDv9qxh
cAjx8ZzCIbGrBJgGMnnpjupIQA5UzgcsU482IJHdNX33DMgpmAUSKBwfcBaKTC9r
upvThjetpI9Ako6xzD9h2lxqNi+asvuWzfAjRAB63i2JFe03YUEoMOcIi9zwu+B2
0O+BZJ0elBxl3ryCi3Gd
-----END CERTIFICATE REQUEST-----";

Crypt::PKCS10->setAPIversion(1);
my $req = Crypt::PKCS10->new($data);

is(scalar $req->subject(), '/C=DE/O=OpenPKI/OU=Branch+Office/OU=IT/CN=John Doe/UID=john.doe/emailAddress=john.doe@openxpki.org');

my $csr_subject = $req->subjectSequence();
is_deeply($csr_subject,[
    [
        {
            'type' => '2.5.4.6',
            'value' => {
                        'printableString' => 'DE'
                        }
        }
    ],
    [
        {
            'value' => {
                        'utf8String' => 'OpenPKI'
                        },
            'type' => '2.5.4.10'
        }
    ],
    [
        {
            'value' => {
                        'utf8String' => 'Branch+Office'
                        },
            'type' => '2.5.4.11'
        }
    ],
    [
        {
            'value' => {
                        'utf8String' => 'IT'
                        },
            'type' => '2.5.4.11'
        }
    ],
    [
        {
            'value' => {
                        'utf8String' => 'John Doe'
                        },
            'type' => '2.5.4.3'
        },
        {
            'type' => '0.9.2342.19200300.100.1.1',
            'value' => {
                        'utf8String' => 'john.doe'
                        }
        }
    ],
    [
        {
            'type' => '1.2.840.113549.1.9.1',
            'value' => {
                        'ia5String' => 'john.doe@openxpki.org'
                        }
        }
    ]
]);
