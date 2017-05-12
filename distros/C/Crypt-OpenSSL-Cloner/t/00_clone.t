#!/opt/local/bin/perl
use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);

BEGIN {
    use_ok("Crypt::OpenSSL::Cloner");
}

my $tmpdir = tempdir(CLEANUP => 1);
my $CA;
my @CERTS;
my $DN_HREF = {
    C => US => O => FooOrg => OU => BigUnit => CN => "Foo big unit trust"
};

$CA = Crypt::OpenSSL::Cloner->new(path => $tmpdir, dn => $DN_HREF);

isa_ok($CA, "Crypt::OpenSSL::Cloner", "new CA with directory");
my $dn_text = $CA->{CA_OBJ}->get_issuer_DN->to_string();
undef $CA;

ok(-f $tmpdir . "/" . $Crypt::OpenSSL::Cloner::CA_BASENAME . ".key",
   "checked for key file");
ok(-f $tmpdir . "/" . $Crypt::OpenSSL::Cloner::CA_BASENAME . ".pem",
   "checked for PEM encoded cert");

$CA = Crypt::OpenSSL::Cloner->new(path => $tmpdir);
isa_ok($CA, "Crypt::OpenSSL::Cloner", "load from existing directory");
is($CA->{CA_OBJ}->get_issuer_DN->to_string, $dn_text,
   "same certificate data(sort of)");

my @pems;
my @pkeys;
foreach my $cert (@CERTS) {
    my ($pem,$privkey) = $CA->clone_cert($cert);
    push @pems, $pem;
    push @pkeys, $privkey;
}
my $certcount = @CERTS;
my $pem_count = (grep $_, @pems);
my $key_count = (grep $_, @pkeys);
ok($pem_count == $key_count &&
   $key_count == $certcount,
   "Got $key_count keys, $pem_count certificates/
   $certcount input");
done_testing();


BEGIN {
push @CERTS, <<PEM;
-----BEGIN CERTIFICATE-----
MIIFVTCCBD2gAwIBAgIHBGX+dPs18DANBgkqhkiG9w0BAQUFADCByjELMAkGA1UE
BhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUxGjAY
BgNVBAoTEUdvRGFkZHkuY29tLCBJbmMuMTMwMQYDVQQLEypodHRwOi8vY2VydGlm
aWNhdGVzLmdvZGFkZHkuY29tL3JlcG9zaXRvcnkxMDAuBgNVBAMTJ0dvIERhZGR5
IFNlY3VyZSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTERMA8GA1UEBRMIMDc5Njky
ODcwHhcNMDkxMjExMDUwMjM2WhcNMTQxMjExMDUwMjM2WjBRMRUwEwYDVQQKEwwq
LmdpdGh1Yi5jb20xITAfBgNVBAsTGERvbWFpbiBDb250cm9sIFZhbGlkYXRlZDEV
MBMGA1UEAxMMKi5naXRodWIuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
CgKCAQEA7dOJw11wcgnzM08acnTZtlqVULtoYZ/3+x8Z4doEMa8VfBp/+XOvHeVD
K1YJAEVpSujEW9/Cd1JRGVvRK9k5ZTagMhkcQXP7MrI9n5jsglsLN2Q5LLcQg3LN
8OokS/rZlC7DhRU5qTr2iNr0J4mmlU+EojdOfCV4OsmDbQIXlXh9R6hVg+4TyBka
szzxX/47AuGF+xFmqwldn0xD8MckXilyKM7UdWhPJHIprjko/N+NT02Dc3QMbxGb
p91i3v/i6xfm/wy/wC0xO9ZZovLdh0pIe20zERRNNJ8yOPbIGZ3xtj3FRu9RC4rG
M+1IYcQdFxu9fLZn6TnPpVKACvTqzQIDAQABo4IBtjCCAbIwDwYDVR0TAQH/BAUw
AwEBADAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwDgYDVR0PAQH/BAQD
AgWgMDMGA1UdHwQsMCowKKAmoCSGImh0dHA6Ly9jcmwuZ29kYWRkeS5jb20vZ2Rz
MS0xMS5jcmwwUwYDVR0gBEwwSjBIBgtghkgBhv1tAQcXATA5MDcGCCsGAQUFBwIB
FitodHRwOi8vY2VydGlmaWNhdGVzLmdvZGFkZHkuY29tL3JlcG9zaXRvcnkvMIGA
BggrBgEFBQcBAQR0MHIwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmdvZGFkZHku
Y29tLzBKBggrBgEFBQcwAoY+aHR0cDovL2NlcnRpZmljYXRlcy5nb2RhZGR5LmNv
bS9yZXBvc2l0b3J5L2dkX2ludGVybWVkaWF0ZS5jcnQwHwYDVR0jBBgwFoAU/axh
MpNsRdbi7oVfmrrndplozOcwIwYDVR0RBBwwGoIMKi5naXRodWIuY29tggpnaXRo
dWIuY29tMB0GA1UdDgQWBBSH0Y8ZbuSHb1OMd5EHUN+jv1VHIDANBgkqhkiG9w0B
AQUFAAOCAQEAwIe/Bbuk1/r38aqb5wlXjoW6tAmLpzLRkKorDOcDUJLtN6a9XqAk
cgMai7NCI1YV+A4IjEENj53mV2xWLpniqLDHI5y2NbQuL2deu1jQSSNz7xE/nZCk
WGt8OEtm6YI2bUsq5EXy078avRbigBko1bqtFuG0s5+nFrKCjhQVIk+GX7cwiyr4
XJ49FxETvePrxNYr7x7n/Jju59KXTw3juPET+bAwNlRXmScjrMylMNUMr3sFcyLz
DciaVnnextu6+L0w1+5KNVbMKndRwgg/cRldBL4AgmtouTC3mlDGGG3U6eV75cdH
D03DXDfrYYjxmWjTRdO2GdbYnt1ToEgxyA==
-----END CERTIFICATE-----
PEM

push @CERTS, <<PEM;
-----BEGIN CERTIFICATE-----
MIIDIjCCAougAwIBAgIQHxn23jXdY6FCkYrVLMCrEjANBgkqhkiG9w0BAQUFADBM
MQswCQYDVQQGEwJaQTElMCMGA1UEChMcVGhhd3RlIENvbnN1bHRpbmcgKFB0eSkg
THRkLjEWMBQGA1UEAxMNVGhhd3RlIFNHQyBDQTAeFw0wOTEyMTgwMDAwMDBaFw0x
MTEyMTgyMzU5NTlaMGkxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpDYWxpZm9ybmlh
MRYwFAYDVQQHFA1Nb3VudGFpbiBWaWV3MRMwEQYDVQQKFApHb29nbGUgSW5jMRgw
FgYDVQQDFA9tYWlsLmdvb2dsZS5jb20wgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJ
AoGBANknyBHye+RFyUa2Y3WDsXd+F0GJgDjxRSegPNnoqABL2QfQut7t9CymrNwn
E+wMwaaZF0LmjSfSgRSwS4L6ssXQuyBZYiijlrVh9nbBbUbS/brGDz3RyXeaWDP2
BnYyrVFfKV9u+BKLrebFCDmzQ0OpW5Ed1+PPUd91WY6NgKtTAgMBAAGjgecwgeQw
DAYDVR0TAQH/BAIwADA2BgNVHR8ELzAtMCugKaAnhiVodHRwOi8vY3JsLnRoYXd0
ZS5jb20vVGhhd3RlU0dDQ0EuY3JsMCgGA1UdJQQhMB8GCCsGAQUFBwMBBggrBgEF
BQcDAgYJYIZIAYb4QgQBMHIGCCsGAQUFBwEBBGYwZDAiBggrBgEFBQcwAYYWaHR0
cDovL29jc3AudGhhd3RlLmNvbTA+BggrBgEFBQcwAoYyaHR0cDovL3d3dy50aGF3
dGUuY29tL3JlcG9zaXRvcnkvVGhhd3RlX1NHQ19DQS5jcnQwDQYJKoZIhvcNAQEF
BQADgYEAicju7fexy+yRP2drx57Tcqo+BElR1CiHNZ1nhPmS9QSZaudDA8jy25IP
VWvjEgaq13Hro0Hg32ZNVK53qcXwjWtnCAReojvNwj6/x1Ciq5B6D7E6eiYDSfXJ
8/a2vR5IbgY89nq+wuHaA6vspH6vNR848xO3z1PQ7BrIjnYQ1A0=
-----END CERTIFICATE-----
PEM
}
