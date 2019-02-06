use strict;
use warnings;
my $sig_cert = "-----BEGIN CERTIFICATE-----
MIIBqDCCAVKgAwIBAgIBATANBgkqhkiG9w0BAQUFADBHMQswCQYDVQQGEwJERTEN
MAsGA1UECAwEYXNkZjENMAsGA1UEBwwEYXNkZjENMAsGA1UECgwEYXNkZjELMAkG
A1UEAwwCY2EwHhcNMTUwMzE1MTI1NTA5WhcNMTYwMzE0MTI1NTA5WjBWMQswCQYD
VQQGEwJERTETMBEGA1UECAwKU29tZS1TdGF0ZTEhMB8GA1UECgwYSW50ZXJuZXQg
V2lkZ2l0cyBQdHkgTHRkMQ8wDQYDVQQDDAZjbGllbnQwXDANBgkqhkiG9w0BAQEF
AANLADBIAkEA04Eoe6STCMGPcc4znCh6KlKnK5eCtrjX3ZlO7hh7RLBPEX1NdAMp
Gg7dwOtypmsMSf9yIkoyp9Ad+zO4bXDfeQIDAQABoxowGDAJBgNVHRMEAjAAMAsG
A1UdDwQEAwIF4DANBgkqhkiG9w0BAQUFAANBAA0+zqbgx+bgtV449kHKfWObgtFO
aK0BeVoKscmmcsRw+xMVgEcJLLHjY6sMdf4AyxT1DhaCOJngIqkMi7r0QFI=
-----END CERTIFICATE-----
";

my $sig_key = "-----BEGIN PRIVATE KEY-----
MIIBVgIBADANBgkqhkiG9w0BAQEFAASCAUAwggE8AgEAAkEA04Eoe6STCMGPcc4z
nCh6KlKnK5eCtrjX3ZlO7hh7RLBPEX1NdAMpGg7dwOtypmsMSf9yIkoyp9Ad+zO4
bXDfeQIDAQABAkBEUINy7EVRnrNmXuPsnGZZJTk5q0ZdHnca7FnCLcYi+Pk1PdEu
KD2jmKIZ97WAxfMb7+EwtP9OuGT5VC9wHvgBAiEA7i2cIskNm3TwB7Slc6A8PICp
+wyC4x2vzCtgoR+mjukCIQDjVJrZQM618XoZWrczKp2j1te5pFAdYNFTudktT40S
EQIhAI82IYHQ/juRLpqThkBmApImkw5+0Vyahw/urSV0kIOxAiEAr/8mSyBDaNTk
xJBY2QIbPWbtaMnvRG9aYEm3+75k5yECIQDj7FLP17i8LGa2sp3qrXP+3cTb4yK/
XgTC1Ra2VYVYSQ==
-----END PRIVATE KEY-----
";

my $req = "-----BEGIN CERTIFICATE REQUEST-----
MIIBtTCCAR4CAQAwVzELMAkGA1UEBhMCQVUxEzARBgNVBAgTClNvbWUtU3RhdGUx
ITAfBgNVBAoTGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDEQMA4GA1UEAxMHZm9v
LmJhcjCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEApws+aot5FvGrzwj4Zijl
MEkaQnKjotER97Rm7q7QqB5eep4S919V7r/t3uh1ku+CDlm8LmVwA3UlrMBTHnyb
oeg+LUQAs74Gzrl2scaKY/T2J4njbpwEzZdTtX8tUBt7iYsvkLkHt/8XyCMCFbb7
MeXJDH0R5OIOJbDicC6HyL8CAwEAAaAeMBwGCSqGSIb3DQEJBzEPEw1GT09CQVJU
RVNUUFdEMA0GCSqGSIb3DQEBBQUAA4GBACHwu5U6KNAsgFkmgU6DNBQXriPwRvvn
uGCzClbjbwGnoi9XCtgepO6I6AbDokjpuuU8/JEGAqKwtRzOsvGJyq4tphAPf/89
/H+xoHva5tgIGv9zUQSj/6Q0B7TEUKLfVC4H0K9wde+5g13l82EzXXrsCjnyB3S7
SLYGjIEJ2RwX
-----END CERTIFICATE REQUEST-----
";

my $enc_cacert = "-----BEGIN CERTIFICATE-----
MIIBmzCCAUWgAwIBAgIBAjANBgkqhkiG9w0BAQUFADBHMQswCQYDVQQGEwJERTEN
MAsGA1UECAwEYXNkZjENMAsGA1UEBwwEYXNkZjENMAsGA1UECgwEYXNkZjELMAkG
A1UEAwwCY2EwHhcNMTUwMzE1MTMwMjIyWhcNMTYwMzE0MTMwMjIyWjBJMQswCQYD
VQQGEwJBVTETMBEGA1UECAwKU29tZS1TdGF0ZTEYMBYGA1UECgwPZW5jcnlwdGlv
biBjZXJ0MQswCQYDVQQDDAJjYTBcMA0GCSqGSIb3DQEBAQUAA0sAMEgCQQCWdhTh
BrT7C1f6EtOKPl5nqBd/9YkTUwDt9qAUBNM6AH6tDFIy85Gk1k60ZwYBYyIZT7kN
2EqnK4zEBRyo2k4jAgMBAAGjGjAYMAkGA1UdEwQCMAAwCwYDVR0PBAQDAgXgMA0G
CSqGSIb3DQEBBQUAA0EAbce5uBBXc7BPVIcQCqIqbkSEBQ735gmV9FB1XJ4tNl+/
qjhv1MBVgGB5CAoETs8mJGHwo2c+5JgDkfMJ6gsIEA==
-----END CERTIFICATE-----";

my $sig_cacert = "-----BEGIN CERTIFICATE-----
MIIB1zCCAYGgAwIBAgIJAIxnK+AvQtveMA0GCSqGSIb3DQEBBQUAMEcxCzAJBgNV
BAYTAkRFMQ0wCwYDVQQIDARhc2RmMQ0wCwYDVQQHDARhc2RmMQ0wCwYDVQQKDARh
c2RmMQswCQYDVQQDDAJjYTAeFw0xNTAzMTUxMjIxNThaFw0xODAxMDIxMjIxNTha
MEcxCzAJBgNVBAYTAkRFMQ0wCwYDVQQIDARhc2RmMQ0wCwYDVQQHDARhc2RmMQ0w
CwYDVQQKDARhc2RmMQswCQYDVQQDDAJjYTBcMA0GCSqGSIb3DQEBAQUAA0sAMEgC
QQC2ZbZXN6Q+k4yECXUBrv3x/zF0F16G9Yx+b9qxdhkP/+BkA5gyRFNEWL+EovU2
00F/mSpYsFW+VlIGW0x0rBvJAgMBAAGjUDBOMB0GA1UdDgQWBBTGyK1AVoV5v/Ou
4FmWrxNg3Aqv5zAfBgNVHSMEGDAWgBTGyK1AVoV5v/Ou4FmWrxNg3Aqv5zAMBgNV
HRMEBTADAQH/MA0GCSqGSIb3DQEBBQUAA0EAFZJdlgEgGTOzRdtPsRY0ezWVow26
1OUUf1Z6x0e9z/Nzkoo2kfI4iDafebvQ1yMqSWKbUjLGAi/YCq2m3p5tHA==
-----END CERTIFICATE-----
";

my $sig_cakey = "-----BEGIN RSA PRIVATE KEY-----
MIIBOwIBAAJBALZltlc3pD6TjIQJdQGu/fH/MXQXXob1jH5v2rF2GQ//4GQDmDJE
U0RYv4Si9TbTQX+ZKliwVb5WUgZbTHSsG8kCAwEAAQJAJ/wuN/qDsBAqiruEAgV5
uDZogfmpiE6GKSWePK8WGXJw4HKay/WcFRVhOmBKskPz0TWon+fykgCXUBS0f9jg
vQIhANocMJCuZm0k51AGUHzHH0+e3KNqdkYtfzFgMUzJexz7AiEA1hVMzCIo/F2s
33O/F2dw+yQC0w83d/dG06kjssoVBwsCIQCy/FEqWcP6Kz+bXyMr0mgyeaaMgDBB
FNL9HPg4EFt0gwIgH31ylnRP4w9EZnn4GdE1ZTuezrzmQ9czq96tSZdAEJECIQCQ
luNLdgk6/rH8iHtN54nKJhTNr4qZWI6b2xSpBAkerw==
-----END RSA PRIVATE KEY-----
";

my $enc_cert = "-----BEGIN CERTIFICATE-----
MIIBmjCCAUSgAwIBAgIBAzANBgkqhkiG9w0BAQUFADBHMQswCQYDVQQGEwJERTEN
MAsGA1UECAwEYXNkZjENMAsGA1UEBwwEYXNkZjENMAsGA1UECgwEYXNkZjELMAkG
A1UEAwwCY2EwHhcNMTUwMzE1MTMwMzI4WhcNMTYwMzE0MTMwMzI4WjBIMQswCQYD
VQQGEwJBVTETMBEGA1UECAwKU29tZS1TdGF0ZTETMBEGA1UECgwKRW5jcnlwdGlv
bjEPMA0GA1UEAwwGY2xpZW50MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBALhqBpcv
JC/0cdUGgFXzGIwwUxHUpK17LDtigQerl69FBGJJns8NZ0oKVT51/3fgLYlXDEZ9
kIbw7jcH2NLq30MCAwEAAaMaMBgwCQYDVR0TBAIwADALBgNVHQ8EBAMCBeAwDQYJ
KoZIhvcNAQEFBQADQQAdBpZ1QuDcnbbJj3yPH85y5cOYL/9d5c1utDeQEIqOFah3
n+Hm9q37a9O3404+jkNZjOwQtANC72KR5QtRtkhq
-----END CERTIFICATE-----
";

my $enc_key = "-----BEGIN PRIVATE KEY-----
MIIBVQIBADANBgkqhkiG9w0BAQEFAASCAT8wggE7AgEAAkEAuGoGly8kL/Rx1QaA
VfMYjDBTEdSkrXssO2KBB6uXr0UEYkmezw1nSgpVPnX/d+AtiVcMRn2QhvDuNwfY
0urfQwIDAQABAkAo1/q7s0otgNNRXg5AewXdzronQdRzQ8uJH4j6XOvMenl571Sp
Wp3y0owl+exEo+Q66QTn6orqbfOk7KYES1mRAiEA3UaGkQB5mkL9CVSK07G46+iu
1hDeOFPtzJwanbYcDpsCIQDVWqQXMgJqE55KTK8l8aSoPiH/e7QkNMK4TBoitDto
eQIger87uMY9rsBIY9udI2/sOBmcmy1CSJbuTFmwPhqel88CIQCXFishqe5/xAjS
QN+/lRGveuCElcuJ4DsMXAgeD1gKsQIhAJwkG1Q5CFsYbAsFsU0Dd7ZI6aiMDi8w
iX5k7rlRcZzQ
-----END PRIVATE KEY-----";

my $enc_cakey = "-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: DES-EDE3-CBC,DD73214CD86AA97E

JoHENnOl+cfDp24t9iJz0UsJMYdMG0nEhI9FNXlOJLKNMnEv3EP7RzvC/MvKSRmD
6HNQGCuzmgRqAzCTUn+8lx0b8W1gVEnb1/OKqhv6qVBYJEKELfSaG+U6+05GYYuP
wtMAES9ijdY1IvvYwm9liJn/DqZdcBKr+41f74jzRO2Q7RA6JR5PpSpw1xvHCQ3M
7hEkXPbhRFFcKH4PiCGr4o8XUcF7gKkeSD7D5OtsqntgT5h2CgPKu7EyckWa1wdG
oiwk8/ocL0I9vewPhOH0tssUZn1GP2bnXTxmpvt25lXLdZHF7zDqLJHd7cZQT9SN
bD6UzOs3aXgkcQeT2Qk8Fi7nFFYUitSg5ihieA777Rrd4IrLBCgU/BiUrh9/afm6
LK4Lg/GAWeK5Tch/2LEg+YMaXQs0+JTKu/NPmgZ7x+E=
-----END RSA PRIVATE KEY-----
";

my $issuedCert = "-----BEGIN CERTIFICATE-----
MIIB7TCCAZegAwIBAgIBBDANBgkqhkiG9w0BAQUFADBHMQswCQYDVQQGEwJERTEN
MAsGA1UECAwEYXNkZjENMAsGA1UEBwwEYXNkZjENMAsGA1UECgwEYXNkZjELMAkG
A1UEAwwCY2EwHhcNMTUwMzE1MTQyMzI1WhcNMTYwMzE0MTQyMzI1WjBXMQswCQYD
VQQGEwJBVTETMBEGA1UECBMKU29tZS1TdGF0ZTEhMB8GA1UEChMYSW50ZXJuZXQg
V2lkZ2l0cyBQdHkgTHRkMRAwDgYDVQQDEwdmb28uYmFyMIGfMA0GCSqGSIb3DQEB
AQUAA4GNADCBiQKBgQCnCz5qi3kW8avPCPhmKOUwSRpCcqOi0RH3tGburtCoHl56
nhL3X1Xuv+3e6HWS74IOWbwuZXADdSWswFMefJuh6D4tRACzvgbOuXaxxopj9PYn
ieNunATNl1O1fy1QG3uJiy+QuQe3/xfIIwIVtvsx5ckMfRHk4g4lsOJwLofIvwID
AQABoxowGDAJBgNVHRMEAjAAMAsGA1UdDwQEAwIF4DANBgkqhkiG9w0BAQUFAANB
AGZRYophSHisfLzjA0EV766X+e7hAK1J+G3IZHHn4WvxRGEGRZmEYMwbV3/gIRW8
bIEcl2LeuPgUGWhLIowjKF0=
-----END CERTIFICATE-----
";

my $sig_cakey_enc = "-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: DES-CBC,4F58E19A09903724

UsnO5Kn0ZlvwdZRvZcQoP3cRLb0I3x28sxOSBlJZrR4y5x4uYmW5huvCUf2Bd6L6
u3ylfXoKVaCdKJ2tCzas0huQeG9mSA6m2D5Wm2y37iyjqtUbI52cMFQOM5qdOrEJ
2cLVHVjNvDxFuRSbIpTeLuABIEtEOkxkJAfe5Uns6iNcg65p95OokwCq3v4+NKGS
6AmkcznuL2l75ITHntYBCiDtoHWRXDm4QioM8hV/T+CxtdWttHz3G6TeQ/XdDicq
X08qHUZg7s7USpfnKfkLOdshlykSD5uldVDM8DEu+quiapbyfJDev7mpzItD0/Ru
+YUiFAfxW1V304+Ifwer4p++TDL+7Ka929j6r4TAEp7OY10tyjPCvUhaiiNH+RYt
4Afd1Z5gdUberBpJCmg6z020fwq1gn3AlXUOxlf+Z2k=
-----END RSA PRIVATE KEY-----
";

my $crl = "-----BEGIN X509 CRL-----
MIHeMIGJAgEBMA0GCSqGSIb3DQEBCwUAMEcxCzAJBgNVBAYTAkRFMQ0wCwYDVQQI
DARhc2RmMQ0wCwYDVQQHDARhc2RmMQ0wCwYDVQQKDARhc2RmMQswCQYDVQQDDAJj
YRcNMTUxMTEyMTcwMDA5WhcNMTUxMjEyMTcwMDA5WqAOMAwwCgYDVR0UBAMCAQEw
DQYJKoZIhvcNAQELBQADQQCZr+Bma6Al8otR2bMTtOXndEVSInsfiSaigzh+TEZq
5fgZ7fdUlkoXpCUJbvudyGSzUtEas9dFQB7M8RGDGiBP
-----END X509 CRL-----
";

my $serial = "1";
my $issuer = "/C=DE/ST=asdf/L=asdf/O=asdf/CN=ca";
my $failinfo = "badAlg";

use Test::More tests => 75;
BEGIN { use_ok('Crypt::LibSCEP') };


my $handle = Crypt::LibSCEP::create_handle({sigalg=>"sha256", encalg=>"aes256"});
my $conf = {handle => $handle};
ok($handle ne "", "handle creation");
my $ca_conf = {passin=>"pass", passwd=>"asdf", sigalg=>"sha256", encalg=>"aes256"};
my $ca_conf2 = {passin=>"pass", passwd=>"foobar", sigalg=>"sha256", encalg=>"aes256"};

#Testing PKCSReq
my $pkcsreq = Crypt::LibSCEP::pkcsreq($conf, $sig_key, $sig_cert, $enc_cacert, $req);
ok($pkcsreq ne "", "pkcsreq creation");
my $pkcsreq_parsed = Crypt::LibSCEP::parse($conf, $pkcsreq);
ok($pkcsreq_parsed ne "", "pkcsreq parsed");
ok(Crypt::LibSCEP::get_transaction_id($pkcsreq_parsed) eq "2F3C88114C283E9A6CD57BB8266CE313DB0BEE0DAF769D770C4E5FFB9C4C1016", "pkcsreq trans id");
ok(Crypt::LibSCEP::get_message_type($pkcsreq_parsed) eq "PKCSReq", "pkcsreq message type");
ok(Crypt::LibSCEP::get_signer_cert($pkcsreq_parsed) eq $sig_cert, "pkcsreq signerCert");
ok(Crypt::LibSCEP::get_senderNonce($pkcsreq_parsed) ne "", "pkcsreq senderNonce");
my $pkcsreq_unwrapped = Crypt::LibSCEP::unwrap($ca_conf, $pkcsreq, $sig_cacert, $enc_cacert, $enc_cakey);
ok($pkcsreq_unwrapped ne "", "pkcsreq unwrap");
ok(Crypt::LibSCEP::get_pkcs10($pkcsreq_unwrapped) eq $req, "pkcsreq get PKCS10");

#Testing GetCert
my $getcert = Crypt::LibSCEP::getcert($conf, $sig_key, $sig_cert, $enc_cacert, $sig_cacert, $serial);
ok($getcert ne "", "getcert creation");
my $getcert_parsed = Crypt::LibSCEP::parse($conf, $getcert);
ok($getcert_parsed ne "", "getcert parsed");
ok(Crypt::LibSCEP::get_transaction_id($getcert_parsed) eq "2BF79F781878B57DC31E8BE733A3425DC09D996BA2F75A3D3F23DBEAEAA6C328", "getcert trans id");
ok(Crypt::LibSCEP::get_message_type($getcert_parsed) eq "GetCert", "getcert message type");
ok(Crypt::LibSCEP::get_signer_cert($getcert_parsed) eq $sig_cert, "getcert signerCert");
ok(Crypt::LibSCEP::get_senderNonce($getcert_parsed) ne "", "getcert senderNonce");
my $getcert_unwrapped = Crypt::LibSCEP::unwrap($ca_conf, $getcert, $sig_cacert, $enc_cacert, $enc_cakey);
ok($getcert_unwrapped ne "", "getcert unwrap");
ok(Crypt::LibSCEP::get_getcert_serial($getcert_unwrapped) eq $serial, "getcert serial");
ok(Crypt::LibSCEP::get_issuer($getcert_unwrapped) eq $issuer, "getcert issuer");

#Testing GetCRL
my $getcrl = Crypt::LibSCEP::getcrl($conf, $sig_key, $sig_cert, $enc_cacert, $sig_cacert);
ok($getcrl ne "", "getcrl creation");
my $getcrl_parsed = Crypt::LibSCEP::parse($conf, $getcrl);
ok($getcrl_parsed ne "", "getcrl parsed");
ok(Crypt::LibSCEP::get_transaction_id($getcrl_parsed) eq "59E435A2C79C77E30C1E8EAC935A3FC20C5C101EADA7918747C6052DD380BA89", "getcrl trans id");
ok(Crypt::LibSCEP::get_message_type($getcrl_parsed) eq "GetCRL", "getcrl message type");
ok(Crypt::LibSCEP::get_signer_cert($getcrl_parsed) eq $sig_cert, "getcrl signerCert");
ok(Crypt::LibSCEP::get_senderNonce($getcrl_parsed) ne "", "getcrl senderNonce");
my $getcrl_unwrapped = Crypt::LibSCEP::unwrap($ca_conf, $getcrl, $sig_cacert, $enc_cacert, $enc_cakey);
ok($getcrl_unwrapped ne "", "getcrl unwrap");
ok(Crypt::LibSCEP::get_getcert_serial($getcrl_unwrapped) eq "10117103329776688094", "getcrl serial");
ok(Crypt::LibSCEP::get_issuer($getcrl_unwrapped) eq $issuer, "getcrl issuer");

#Testing GetCertInitial
my $getcertinitial = Crypt::LibSCEP::getcertinitial($conf, $sig_key, $sig_cert, $enc_cacert, $req, $sig_cacert);
ok($getcertinitial ne "", "getcertinitial creation");
my $getcertinitial_parsed = Crypt::LibSCEP::parse($conf, $getcertinitial);
ok($getcertinitial_parsed ne "", "getcertinitial parsed");
ok(Crypt::LibSCEP::get_transaction_id($getcertinitial_parsed) eq "2F3C88114C283E9A6CD57BB8266CE313DB0BEE0DAF769D770C4E5FFB9C4C1016", "getcertinitial trans id");
ok(Crypt::LibSCEP::get_message_type($getcertinitial_parsed) eq "GetCertInitial", "getcertinitial message type");
ok(Crypt::LibSCEP::get_signer_cert($getcertinitial_parsed) eq $sig_cert, "getcertinitial signerCert");
ok(Crypt::LibSCEP::get_senderNonce($getcertinitial_parsed) ne "", "getcertinitial senderNonce");
my $getcertinitial_unwrapped = Crypt::LibSCEP::unwrap($ca_conf, $getcertinitial, $sig_cacert, $enc_cacert, $enc_cakey);
ok($getcertinitial_unwrapped ne "", "getcertinitial unwrap");
ok(Crypt::LibSCEP::get_subject($getcertinitial_unwrapped) eq "/C=AU/ST=Some-State/O=Internet Widgits Pty Ltd/CN=foo.bar", "getcertinitial subject");
ok(Crypt::LibSCEP::get_issuer($getcertinitial_unwrapped) eq $issuer, "getcertinitial issuer");

#Testing CertRep PENDING to PKCSReq
my $senderNonce_pkcsreq = Crypt::LibSCEP::get_senderNonce($pkcsreq_parsed);
my $certrep_pending = Crypt::LibSCEP::create_pending_reply($ca_conf, $sig_cakey, $sig_cacert, $pkcsreq);
my $certrep_pending_wo_p7 = Crypt::LibSCEP::create_pending_reply_wop7($ca_conf, $sig_cakey, $sig_cacert, "2F3C88114C283E9A6CD57BB8266CE313DB0BEE0DAF769D770C4E5FFB9C4C1016", $senderNonce_pkcsreq);
my @certreps_pending = ($certrep_pending, $certrep_pending_wo_p7);
foreach my $test (@certreps_pending) {
	ok($test ne "", "CertRep PENDING creation");
	my $certrep_pending_parsed = Crypt::LibSCEP::parse($conf, $test);
	ok($certrep_pending_parsed ne "", "CertRep PENDING parsed");
	ok(Crypt::LibSCEP::get_transaction_id($certrep_pending_parsed) eq "2F3C88114C283E9A6CD57BB8266CE313DB0BEE0DAF769D770C4E5FFB9C4C1016", "CertRep PENDING trans id");
	ok(Crypt::LibSCEP::get_message_type($certrep_pending_parsed) eq "CertRep", "CertRep PENDING message type");
	ok(Crypt::LibSCEP::get_signer_cert($certrep_pending_parsed) eq $sig_cacert, "CertRep PENDING signerCert");
	ok(Crypt::LibSCEP::get_senderNonce($certrep_pending_parsed) ne "", "CertRep PENDING senderNonce");
	#ok(Crypt::LibSCEP::get_failInfo($certrep_pending_parsed) eq $failinfo, "CertRep PENDING failInfo");
	ok(Crypt::LibSCEP::get_recipientNonce($certrep_pending_parsed) eq $senderNonce_pkcsreq, "CertRep PENDING recipientNonce");
	ok(Crypt::LibSCEP::get_pkiStatus($certrep_pending_parsed) eq "PENDING", "CertRep PENDING Status");
}

=pod
#Testing CertRep PENDING to GetCert
my $sn = Crypt::LibSCEP::get_senderNonce($getcert_parsed);
my $certrep_pending = Crypt::LibSCEP::create_pending_reply($ca_conf, $sig_cakey, $sig_cacert, $getcert);
my $certrep_pending_wo_p7 = Crypt::LibSCEP::create_pending_reply_wop7($ca_conf, $sig_cakey, $sig_cacert, "2BF79F781878B57DC31E8BE733A3425DC09D996BA2F75A3D3F23DBEAEAA6C328", $sn);
my @certreps_pending = ($certrep_pending, $certrep_pending_wo_p7);
foreach my $test (@certreps_pending) {
	ok($test ne "", "CertRep PENDING creation");
	my $certrep_pending_parsed = Crypt::LibSCEP::parse($conf, $test);
	ok($certrep_pending_parsed ne "", "CertRep PENDING parsed");
	ok(Crypt::LibSCEP::get_transaction_id($certrep_pending_parsed) eq "2BF79F781878B57DC31E8BE733A3425DC09D996BA2F75A3D3F23DBEAEAA6C328", "CertRep PENDING trans id");
	ok(Crypt::LibSCEP::get_message_type($certrep_pending_parsed) eq "CertRep", "CertRep PENDING message type");
	ok(Crypt::LibSCEP::get_signer_cert($certrep_pending_parsed) eq $sig_cacert, "CertRep PENDING signerCert");
	ok(Crypt::LibSCEP::get_senderNonce($certrep_pending_parsed) ne "", "CertRep PENDING senderNonce");
	ok(Crypt::LibSCEP::get_recipientNonce($certrep_pending_parsed) eq $sn, "CertRep PENDING recipientNonce");
	ok(Crypt::LibSCEP::get_pkiStatus($certrep_pending_parsed) eq "PENDING", "CertRep PENDING Status");
}

#Testing CertRep PENDING to GetCRL
my $sn = Crypt::LibSCEP::get_senderNonce($getcrl_parsed);
my $certrep_pending = Crypt::LibSCEP::create_pending_reply($ca_conf, $sig_cakey, $sig_cacert, $getcrl);
my $certrep_pending_wo_p7 = Crypt::LibSCEP::create_pending_reply_wop7($ca_conf, $sig_cakey, $sig_cacert, "59E435A2C79C77E30C1E8EAC935A3FC20C5C101EADA7918747C6052DD380BA89", $sn);
my @certreps_pending = ($certrep_pending, $certrep_pending_wo_p7);
foreach my $test (@certreps_pending) {
	ok($test ne "", "CertRep PENDING creation");
	my $certrep_pending_parsed = Crypt::LibSCEP::parse($conf, $test);
	ok($certrep_pending_parsed ne "", "CertRep PENDING parsed");
	ok(Crypt::LibSCEP::get_transaction_id($certrep_pending_parsed) eq "59E435A2C79C77E30C1E8EAC935A3FC20C5C101EADA7918747C6052DD380BA89", "CertRep PENDING trans id");
	ok(Crypt::LibSCEP::get_message_type($certrep_pending_parsed) eq "CertRep", "CertRep PENDING message type");
	ok(Crypt::LibSCEP::get_signer_cert($certrep_pending_parsed) eq $sig_cacert, "CertRep PENDING signerCert");
	ok(Crypt::LibSCEP::get_senderNonce($certrep_pending_parsed) ne "", "CertRep PENDING senderNonce");
	ok(Crypt::LibSCEP::get_recipientNonce($certrep_pending_parsed) eq $sn, "CertRep PENDING recipientNonce");
	ok(Crypt::LibSCEP::get_pkiStatus($certrep_pending_parsed) eq "PENDING", "CertRep PENDING Status");
}

#Testing CertRep PENDING to GetCertInitial
my $sn = Crypt::LibSCEP::get_senderNonce($getcertinitial_parsed);
my $certrep_pending = Crypt::LibSCEP::create_pending_reply($ca_conf, $sig_cakey, $sig_cacert, $getcertinitial);
my $certrep_pending_wo_p7 = Crypt::LibSCEP::create_pending_reply_wop7($ca_conf, $sig_cakey, $sig_cacert, "2F3C88114C283E9A6CD57BB8266CE313DB0BEE0DAF769D770C4E5FFB9C4C1016", $sn);
my @certreps_pending = ($certrep_pending, $certrep_pending_wo_p7);
foreach my $test (@certreps_pending) {
	ok($test ne "", "CertRep PENDING creation");
	my $certrep_pending_parsed = Crypt::LibSCEP::parse($conf, $test);
	ok($certrep_pending_parsed ne "", "CertRep PENDING parsed");
	ok(Crypt::LibSCEP::get_transaction_id($certrep_pending_parsed) eq "2F3C88114C283E9A6CD57BB8266CE313DB0BEE0DAF769D770C4E5FFB9C4C1016", "CertRep PENDING trans id");
	ok(Crypt::LibSCEP::get_message_type($certrep_pending_parsed) eq "CertRep", "CertRep PENDING message type");
	ok(Crypt::LibSCEP::get_signer_cert($certrep_pending_parsed) eq $sig_cacert, "CertRep PENDING signerCert");
	ok(Crypt::LibSCEP::get_senderNonce($certrep_pending_parsed) ne "", "CertRep PENDING senderNonce");
	ok(Crypt::LibSCEP::get_recipientNonce($certrep_pending_parsed) eq $sn, "CertRep PENDING recipientNonce");
	ok(Crypt::LibSCEP::get_pkiStatus($certrep_pending_parsed) eq "PENDING", "CertRep PENDING Status");
}

=cut

#Testing CertRep FAILURE to PKCSReq, only check the things that change and believe the rest
$senderNonce_pkcsreq = Crypt::LibSCEP::get_senderNonce($pkcsreq_parsed);
my $certrep_failure = Crypt::LibSCEP::create_error_reply($ca_conf, $sig_cakey, $sig_cacert, $pkcsreq, "badTime");
my $certrep_failure_wo_p7 = Crypt::LibSCEP::create_error_reply_wop7($ca_conf, $sig_cakey, $sig_cacert, "2F3C88114C283E9A6CD57BB8266CE313DB0BEE0DAF769D770C4E5FFB9C4C1016", $senderNonce_pkcsreq, "badTime");
my @certreps_failure = ($certrep_failure, $certrep_failure_wo_p7);
foreach my $test (@certreps_failure) {
	ok($test ne "", "CertRep FAILURE creation");
	my $certrep_failure_parsed = Crypt::LibSCEP::parse($conf, $test);
	ok($certrep_failure_parsed ne "", "CertRep Failure parsed");
	ok(Crypt::LibSCEP::get_failInfo($certrep_failure_parsed) eq "badTime", "CertRep FAILURE failInfo");
	ok(Crypt::LibSCEP::get_pkiStatus($certrep_failure_parsed) eq "FAILURE", "CertRep FAILURE Status");
}

#Testing CertRep SUCCESS to PKCSReq
#different certs will be used. The former one will automatically encrypt the message with the signer certificate. The latter one does it right
my $certrep_success = Crypt::LibSCEP::create_certificate_reply($ca_conf2, $sig_cakey_enc, $sig_cacert, $pkcsreq, $issuedCert . "\n" . $sig_cacert);
my $certrep_success_wo_p7 = Crypt::LibSCEP::create_certificate_reply_wop7($ca_conf2, $sig_cakey, $sig_cacert, "2F3C88114C283E9A6CD57BB8266CE313DB0BEE0DAF769D770C4E5FFB9C4C1016", $senderNonce_pkcsreq, $enc_cert, $issuedCert . "\n" . $sig_cacert);
my @certreps_success = ($certrep_success, $certrep_success_wo_p7);
foreach my $test (@certreps_success) {
	ok($test ne "", "CertRep SUCCESS creation");
	my $certrep_success_parsed = Crypt::LibSCEP::parse($conf, $test);
	ok($certrep_success_parsed ne "", "CertRep SUCCESS parsed");
	ok(Crypt::LibSCEP::get_pkiStatus($certrep_success_parsed) eq "SUCCESS", "CertRep SUCCESS status");
}
my $certrep_success_unwrapped = Crypt::LibSCEP::unwrap($conf, $certrep_success, $sig_cacert, $sig_cert, $sig_key);
my $certrep_success_unwrapped_wo_p7 = Crypt::LibSCEP::unwrap($conf, $certrep_success_wo_p7, $sig_cacert, $enc_cert, $enc_key);
ok($certrep_success_unwrapped ne "", "CertRep SUCCESS unwrap");
ok($certrep_success_unwrapped_wo_p7 ne "", "CertRep SUCCESS unwrap");
ok(Crypt::LibSCEP::get_cert($certrep_success_unwrapped) eq $issuedCert . $sig_cacert, "CertRep SUCCESS cert");
ok(Crypt::LibSCEP::get_cert($certrep_success_unwrapped_wo_p7) eq $issuedCert . $sig_cacert, "CertRep SUCCESS cert");

#Testing CertRep SUCCESS to GetCRL
my $certrep_success_crl = Crypt::LibSCEP::create_crl_reply($ca_conf2, $sig_cakey_enc, $sig_cacert, $getcrl, $crl);
ok($certrep_success_crl ne "", "CertRep SUCCESS unwrap");
my $certrep_success_crl_unwrapped = Crypt::LibSCEP::unwrap($conf, $certrep_success_crl, $sig_cacert, $sig_cert, $sig_key);
ok($certrep_success_crl_unwrapped ne "", "CertRep SUCCESS CRL unwrap");
ok(Crypt::LibSCEP::get_crl($certrep_success_crl_unwrapped) eq $crl, "CertRep SUCCESS crl");

#### my $certrep_success_crl = Crypt::LibSCEP::create_crl_reply($ca_conf2, $sig_cakey_enc, $sig_cacert, $getcrl, $crl);


#Testing create_nextca_reply
ok(Crypt::LibSCEP::create_nextca_reply($conf, $issuedCert . "\n" . $sig_cacert, $sig_cacert, $sig_cakey) ne "", "create_nextca_reply");

#Coment in and adjust if you want to test the engine support
#Note that you need to add the corresponding private key into the engine etc.
=pod 
#Testing PKCS#11 engine
my $label = "pkcs11";
my $so = "/usr/lib/engines/engine_pkcs11.so";
my $module = "/usr/lib/softhsm/libsofthsm.so";
my $pin = "123456";
my $id = "FFFF";
my $engine_conf = {module => $module, label => $label, so => $so, pin => $pin};
Crypt::LibSCEP::create_engine({handle=>$handle}, $engine_conf);
$pkcsreq = Crypt::LibSCEP::pkcsreq({handle=>$handle}, $id, $sig_cert, $enc_cert, $req);
ok($pkcsreq ne "", "CertRep SUCCESS unwrap");

Crypt::LibSCEP::cleanup($handle);
my $pkcsreq_unwrapped = Crypt::LibSCEP::unwrap($ca_conf, $pkcsreq, $sig_cacert, $enc_cert, $enc_key);
ok($pkcsreq_unwrapped ne "", "pkcsreq unwrap");
ok(Crypt::LibSCEP::get_pkcs10($pkcsreq_unwrapped) eq $req, "pkcsreq get PKCS10");
=cut