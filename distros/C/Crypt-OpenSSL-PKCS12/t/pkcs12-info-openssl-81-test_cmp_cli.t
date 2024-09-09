use strict;
use warnings;
use Test::More;
use Digest::SHA qw/sha256_hex/;
use Crypt::OpenSSL::Guess qw/openssl_version/;

my ($major, $minor, $patch) = openssl_version();
BEGIN { use_ok('Crypt::OpenSSL::PKCS12') };
my $openssl_output =<< 'OPENSSL_END';
MAC: sha1, Iteration 2048
MAC length: 20, salt length: 8
PKCS7 Encrypted data: PBES2, PBKDF2, AES-256-CBC, Iteration 2048, PRF hmacWithSHA256
Certificate bag
Bag Attributes
    localKeyID: CF 6B 1F EF D7 B4 D2 96 04 94 60 F6 29 16 75 3A E3 C8 5D 9F 
subject=C = AU, ST = Some-State, O = Internet Widgits Pty Ltd, CN = leaf
issuer=C = AU, ST = Some-State, O = Internet Widgits Pty Ltd, CN = subinterCA
-----BEGIN CERTIFICATE-----
MIIDfjCCAmagAwIBAgIJAKRNsDKacUqNMA0GCSqGSIb3DQEBCwUAMFoxCzAJBgNV
BAYTAkFVMRMwEQYDVQQIEwpTb21lLVN0YXRlMSEwHwYDVQQKExhJbnRlcm5ldCBX
aWRnaXRzIFB0eSBMdGQxEzARBgNVBAMTCnN1YmludGVyQ0EwHhcNMTUwNzAyMTMx
OTQ5WhcNMzUwNzAyMTMxOTQ5WjBUMQswCQYDVQQGEwJBVTETMBEGA1UECBMKU29t
ZS1TdGF0ZTEhMB8GA1UEChMYSW50ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMQ0wCwYD
VQQDEwRsZWFmMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAv0Qo9WC/
BKA70LtQJdwVGSXqr9dut3cQmiFzTb/SaWldjOT1sRNDFxSzdTJjU/8cIDEZvaTI
wRxP/dtVQLjc+4jzrUwz93NuZYlsEWUEUg4Lrnfs0Nz50yHk4rJhVxWjb8Ii/wRB
ViWHFExP7CwTkXiTclC1bCqTuWkjxF3thTfTsttRyY7qNkz2JpNx0guD8v4otQoY
jA5AEZvK4IXLwOwxol5xBTMvIrvvff2kkh+c7OC2QVbUTow/oppjqIKCx2maNHCt
LFTJELf3fwtRJLJsy4fKGP0/6kpZc8Sp88WK4B4FauF9IV1CmoAJUC1vJxhagHIK
fVtFjUWs8GPobQIDAQABo00wSzAJBgNVHRMEAjAAMB0GA1UdDgQWBBQcHcT+8SVG
IRlN9YTuM9rlz7UZfzAfBgNVHSMEGDAWgBTpZ30QdMGarrhMPwk+HHAV3R8aTzAN
BgkqhkiG9w0BAQsFAAOCAQEAGjmSkF8is+v0/RLcnSRiCXENz+yNi4pFCAt6dOtT
6Gtpqa1tY5It9lVppfWb26JrygMIzOr/fB0r1Q7FtZ/7Ft3P6IXVdk3GDO0QsORD
2dRAejhYpc5c7joHxAw9oRfKrEqE+ihVPUTcfcIuBaalvuhkpQRmKP71ws5DVzOw
QhnMd0TtIrbKHaNQ4kNsmSY5fQolwB0LtNfTus7OEFdcZWhOXrWImKXN9jewPKdV
mSG34NfXOnA6qx0eQg06z+TkdrptH6j1Va2vS1/bL+h1GxjpTHlvTGaZYxaloIjw
y/EzY5jygRoABnR3eBm15CYZwwKL9izIq1H3OhymEi/Ycg==
-----END CERTIFICATE-----
Certificate bag
Bag Attributes: <No Attributes>
subject=C = AU, ST = Some-State, O = Internet Widgits Pty Ltd, CN = subinterCA
issuer=C = AU, ST = Some-State, O = Internet Widgits Pty Ltd, CN = interCA
-----BEGIN CERTIFICATE-----
MIIDhDCCAmygAwIBAgIJAJkv2OGshkmUMA0GCSqGSIb3DQEBCwUAMFcxCzAJBgNV
BAYTAkFVMRMwEQYDVQQIEwpTb21lLVN0YXRlMSEwHwYDVQQKExhJbnRlcm5ldCBX
aWRnaXRzIFB0eSBMdGQxEDAOBgNVBAMTB2ludGVyQ0EwHhcNMTUwNzAyMTMxODIz
WhcNMzUwNzAyMTMxODIzWjBaMQswCQYDVQQGEwJBVTETMBEGA1UECBMKU29tZS1T
dGF0ZTEhMB8GA1UEChMYSW50ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMRMwEQYDVQQD
EwpzdWJpbnRlckNBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA/zQj
vhbU7RWDsRaEkVUBZWR/PqZ49GoE9p3OyRN4pkt1c1yb2ARVkYZP5e9gHb04wPVz
2+FYy+2mNkl+uAZbcK5w5fWO3WJIEn57he4MkWu3ew1nJeSv3na8gyOoCheG64kW
VbA2YL92mR7QoSCo4SP7RmykLrwj6TlDxqgH6DxKSD/CpdCHE3DKAzAiri3GVc90
OJAszYHlje4/maVIOayGROVET3xa5cbtRJl8IBgmqhMywtz4hhY/XZTvdEn290aL
857Hk7JjogA7mLKi07yKzknMxHV+k6JX7xJEttkcNQRFHONWZG1T4mRY1Drh6VbJ
Gb+0GNIldNLQqigkfwIDAQABo1AwTjAMBgNVHRMEBTADAQH/MB0GA1UdDgQWBBTp
Z30QdMGarrhMPwk+HHAV3R8aTzAfBgNVHSMEGDAWgBQY+tYjuY9dXRN9Po+okcfZ
YcAXLjANBgkqhkiG9w0BAQsFAAOCAQEAgVUsOf9rdHlQDw4clP8GMY7QahfXbvd8
8o++P18KeInQXH6+sCg0axZXzhOmKwn+Ina3EsOP7xk4aKIYwJ4A1xBuT7fKxquQ
pbJyjkEBsNRVLC9t4gOA0FC791v5bOCZjyff5uN+hy8r0828nVxha6CKLqwrPd+E
mC7DtilSZIgO2vwbTBL6ifmw9n1dd/Bl8Wdjnl7YJqTIf0Ozc2SZSMRUq9ryn4Wq
YrjRl8NwioGb1LfjEJ0wJi2ngL3IgaN94qmDn10OJs8hlsufwP1n+Bca3fsl0m5U
gUMG+CXxbF0kdCKZ9kQb1MJE4vOk6zfyBGQndmQnxHjt5botI/xpXg==
-----END CERTIFICATE-----
Certificate bag
Bag Attributes: <No Attributes>
subject=C = AU, ST = Some-State, O = Internet Widgits Pty Ltd, CN = interCA
issuer=C = AU, ST = Some-State, O = Internet Widgits Pty Ltd, CN = rootCA
-----BEGIN CERTIFICATE-----
MIIDgDCCAmigAwIBAgIJANnoWlLlEsTgMA0GCSqGSIb3DQEBCwUAMFYxCzAJBgNV
BAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMSEwHwYDVQQKDBhJbnRlcm5ldCBX
aWRnaXRzIFB0eSBMdGQxDzANBgNVBAMMBnJvb3RDQTAeFw0xNTA3MDIxMzE3MDVa
Fw0zNTA3MDIxMzE3MDVaMFcxCzAJBgNVBAYTAkFVMRMwEQYDVQQIEwpTb21lLVN0
YXRlMSEwHwYDVQQKExhJbnRlcm5ldCBXaWRnaXRzIFB0eSBMdGQxEDAOBgNVBAMT
B2ludGVyQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC7s0ejvpQO
nvfwD+e4R+9WQovtrsqOTw8khiREqi5JlmAFbpDEFam18npRkt6gOcGMnjuFzuz6
iEuQmeeyh0BqWAwpMgWMMteEzLOAaqkEl//J2+WgRbA/8pmwHfbPW/d+f3bp64Fo
D1hQAenBzXmLxVohEQ9BA+xEDRkL/cA3Y+k/O1C9ORhSQrJNsB9aE3zKbFHd9mOm
H4aNSsF8On3SqlRVOCQine5c6ACSd0HUEjYy9aObqY47ySNULbzVq5y6VOjMs0W+
2G/XqrcVkxzf9bVqyVBrrAJrnb35/y/iK0zWgJBP+HXhwr5mMTvNuEirBeVYuz+6
hUerUbuJhr0FAgMBAAGjUDBOMAwGA1UdEwQFMAMBAf8wHQYDVR0OBBYEFBj61iO5
j11dE30+j6iRx9lhwBcuMB8GA1UdIwQYMBaAFIVWiTXinwAa4YYDC0uvdhJrM239
MA0GCSqGSIb3DQEBCwUAA4IBAQDAU0MvL/yZpmibhxUsoSsa97UJbejn5IbxpPzZ
4WHw8lsoUGs12ZHzQJ9LxkZVeuccFXy9yFEHW56GTlkBmD2qrddlmQCfQ3m8jtZ9
Hh5feKAyrqfmfsWF5QPjAmdj/MFdq+yMJVosDftkmUmaBHjzbvbcq1sWh/6drH8U
7pdYRpfeEY8dHSU6FHwVN/H8VaBB7vYYc2wXwtk8On7z2ocIVHn9RPkcLwmwJjb/
e4jmcYiyZev22KXQudeHc4w6crWiEFkVspomn5PqDmza3rkdB3baXFVZ6sd23ufU
wjkiKKtwRBwU+5tCCagQZoeQ5dZXQThkiH2XEIOCOLxyD/tb
-----END CERTIFICATE-----
Certificate bag
Bag Attributes: <No Attributes>
subject=C = AU, ST = Some-State, O = Internet Widgits Pty Ltd, CN = rootCA
issuer=C = AU, ST = Some-State, O = Internet Widgits Pty Ltd, CN = rootCA
-----BEGIN CERTIFICATE-----
MIIDfzCCAmegAwIBAgIJAIhDKcvC6xWaMA0GCSqGSIb3DQEBCwUAMFYxCzAJBgNV
BAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMSEwHwYDVQQKDBhJbnRlcm5ldCBX
aWRnaXRzIFB0eSBMdGQxDzANBgNVBAMMBnJvb3RDQTAeFw0xNTA3MDIxMzE1MTFa
Fw0zNTA3MDIxMzE1MTFaMFYxCzAJBgNVBAYTAkFVMRMwEQYDVQQIDApTb21lLVN0
YXRlMSEwHwYDVQQKDBhJbnRlcm5ldCBXaWRnaXRzIFB0eSBMdGQxDzANBgNVBAMM
BnJvb3RDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMDxa3eIrDXf
+3NTL5KAL3QWMk31ECBvbDqO0dxr4S4+wwQPv5vEyRLR5AtFl+UGzWY64eDiK9+i
xOx70z08iv9edKCrpwNqFlteksR+W3mKadS8g16uQpJ0pSvnAMGp3NWxUwcPc/eO
rRQ+JZ7lHubMkc2VDIBEIMP9F8+RPWMQHBRb+8OowYiyd/+c2/xqRERE94XsCCzU
34Gjecn+HpuTFlO3l6u+Txql4vpGBeQNnCqkzLkeIaBsxKtZsEA5u/mIrf3fjbQL
r35B4CE8yDNFSYQvkwbu/U/tT/O8m978JV5V1XXUxXs6QDUGn8SEtGyTDK83Wq+2
QU0mIxy4ArMCAwEAAaNQME4wDAYDVR0TBAUwAwEB/zAdBgNVHQ4EFgQUhVaJNeKf
ABrhhgMLS692Emszbf0wHwYDVR0jBBgwFoAUhVaJNeKfABrhhgMLS692Emszbf0w
DQYJKoZIhvcNAQELBQADggEBADIKvyoK4rtPQ86I2lo5EDeAuzctXi2I3SZpnOe0
mCCxJeZhWW0S7JuHvlfhEgXFBPEXzhS4HJLUlZUsWyiJ+3KcINMygaiF7MgIe6hZ
WzpsMatS4mbNFElc89M+YryRFrQc9d1Uqjxhl3ms5MhDNcMP/PNwHa/wnIoqkpNI
qtDoR741wcZ7bdr6XVdF8+pBjzbBPPRSf24x3bqavHBWcTjcSVcM/ZEXxeqH5SN0
GbK2mQxrogX4UWjtl+DfYvl+ejpEcYNXKEmIabUUHtpG42544cuPtZizLW5bt/aT
JBQfpPZpvf9MUlACxUONFOLQdZ8SXpSJ0e93iX2J2Z52mSQ=
-----END CERTIFICATE-----
PKCS7 Data
Shrouded Keybag: PBES2, PBKDF2, AES-256-CBC, Iteration 2048, PRF hmacWithSHA256
Bag Attributes
    localKeyID: CF 6B 1F EF D7 B4 D2 96 04 94 60 F6 29 16 75 3A E3 C8 5D 9F 
Key Attributes: <No Attributes>
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC/RCj1YL8EoDvQ
u1Al3BUZJeqv1263dxCaIXNNv9JpaV2M5PWxE0MXFLN1MmNT/xwgMRm9pMjBHE/9
21VAuNz7iPOtTDP3c25liWwRZQRSDguud+zQ3PnTIeTismFXFaNvwiL/BEFWJYcU
TE/sLBOReJNyULVsKpO5aSPEXe2FN9Oy21HJjuo2TPYmk3HSC4Py/ii1ChiMDkAR
m8rghcvA7DGiXnEFMy8iu+99/aSSH5zs4LZBVtROjD+immOogoLHaZo0cK0sVMkQ
t/d/C1EksmzLh8oY/T/qSllzxKnzxYrgHgVq4X0hXUKagAlQLW8nGFqAcgp9W0WN
RazwY+htAgMBAAECggEAHV8KKyRAMSWqCdO56xZw5vu7nmUmy2WtVv3sBvR+C1Hy
28ANOrQKiXDUXhruxedXGlpv6X90lLMUVZdo8BdzV+0f/mzFTiqbuVvxDHrGvxMJ
GDGyXCCS/KknzOg3qnfYMUFOvnqYzfHVXHibjVj3aE9r1RIvyfx/0ukiZPVHlD1K
Ej9FQKjA/LOELo4aQVIEm7vafIDdYrTOdeerlM2xNF0ks66Dt6gkm+E49/Led41B
XR/aND7bAMoJi+fqLiP0VIuBgL++iuqh8R28UEfGXfvjXXsXoNd0EKHIPgIPm+ym
UHTNwTFFQJPn6IGp/m5zwJssd7I2Tq9Jp/kGWMdawQKBgQD3dCeUqxXJyAJCoe3a
rwQhnmnuSwZhFV8ETOB62w12nG9LCsvItAQvkAobe6md06h8J4mcu5AXWP3ngWMK
zlj7xLLYfUPUQ+sdIGniKDYXlo7FPe9hE52/7+YXhlTOUiW/eM0PPkigtrGb2+Fd
O0stS1DJO54YOarCWG3Qqvf+BwKBgQDF3zpDbeNPgOYmpSX6DSVZ1zZ2B6PSPAV8
nYETD9Dnm8eOqP3qgBflBBkU5SFlTw6138OUvOWwWfSk5pJb9EHiXkq/xpv5mnF8
BXoarjueV/OYQYbHjBygvTGQe5+JeDSypoZS0QxIoWHE9BmFaiNSKYr/5ggXr2ai
XEDob2aI6wKBgQDyYgJLK3HCHnmoTviu1fPUAll8olxzR/20NqFDdcGwRvb0qHSH
+VyIQizEUtMH10UXp5qxvT8cv3ylASXEde7PXhJY4ApKpuRruU49ymmBnWXnag1K
J27DjPbyYBA9sFVtQaSKo9V8Jre+FRigu+2dRkKxegYXcJUEnJ2kYXNcjQKBgQC2
3cmDvY+gzxhkSKYjRHjrYXjEdeURi0Tq2MkL68b99Trk/grD6KOslC/13pgRf5Gx
xd2DnVuMsmXk6+4BK2ikIs5kE9HcSL5uhsVE2RbiDJhkctJzompmptKim41iR4Q0
Qq/K48W9bd/kXE8lvGRuL1R1kIqUERcCH84gwat6BwKBgELxtLvOToo0PLyra4L+
b+DotEzGlvwbiOytwujK4mzfMNyQGNC4slAg4xdxAFY3WH4Mp6QXZ5yvd8kAnIS/
ilTgK3av9lNgUx0lPIBuPDSao6NRHiex06G3+8Ju3RBbcddhNxV0KcWoG16UqcjX
YqgLSMA70QAkZnqQT83Abp1C
-----END PRIVATE KEY-----
OPENSSL_END
if ($major eq '1.0') {
  $openssl_output =~ s/MAC: sha1, Iteration 2048/MAC Iteration 2048/g;
  $openssl_output =~ s/MAC length: .*/MAC verified OK/;
}
my $pass   = "12345";
my $pkcs12 = Crypt::OpenSSL::PKCS12->new_from_file('certs/signer.p12');

my $info = $pkcs12->info($pass);

ok(sha256_hex($info) eq sha256_hex($openssl_output), "Output matches OpenSSL");

my $info_hash = $pkcs12->info_as_hash($pass);

if ($major gt '1.0') {
  like($info_hash->{mac}{digest}, qr/sha1/, "MAC Digest is sha1");
  like($info_hash->{mac}{length}, qr/20/, "MAC length is 20");
  like($info_hash->{mac}{salt_length}, qr/8/, "MAC salt_length is 8");
}

like($info_hash->{mac}{iteration}, qr/2048/, "MAC Iteration is 2048");
my $pkcs7_cnt = scalar @{$info_hash->{pkcs7_data}};

ok($info_hash->{pkcs7_data}, "pkcs7_data key exists");
for (my $i = 0; $i < $pkcs7_cnt; $i++) {
  my $bags = $info_hash->{pkcs7_data}[$i]->{bags};

  is(scalar @$bags, 1, "One bag in pkcs7_data");

  my $bag_attributes = @$bags[0]->{bag_attributes};

  is(keys %$bag_attributes, 1, "Two bag attributes in pkcs7_data bag");

  foreach my $attribute (keys %$bag_attributes) {
        like($bag_attributes->{localKeyID}, qr/CF 6B 1F EF D7 B4 D2 96 04 94 60 F6 29 16 75 3A E3 C8 5D 9F/, "localKeyID matches") if $attribute eq "localKeyID";
  }

  like(@$bags[0]->{key}, qr/PRIVATE KEY/, "pkcs7_data found private key");
  like(@$bags[0]->{key}, qr/OqP3qgBflBBkU5SFlTw6138OUvOWwWfSk5pJ/, "pkcs7_data key matches");
  like(@$bags[0]->{parameters}->{iteration}, qr/2048/, "pkcs7_data parameters iteration matches");
  like(@$bags[0]->{parameters}->{nid_long_name}, qr/PBKDF2/, "pkcs7_data parameters nid_long_name matches");
  like(@$bags[0]->{parameters}->{nid_short_name}, qr/PBKDF2/, "pkcs7_bag parameters nid_short_name matches");
  like(@$bags[0]->{type}, qr/shrouded_keybag/, "pkcs7_data bag type matches");
}

my $pkcs7_enc_cnt = scalar @{$info_hash->{pkcs7_encrypted_data}};

ok($info_hash->{pkcs7_encrypted_data}, "pkcs7_encrypted_data key exists");
for (my $i = 0; $i < $pkcs7_enc_cnt; $i++) {
  my $bags = $info_hash->{pkcs7_encrypted_data}[$i]->{bags};

  is(scalar @$bags, 4, "Two bags in pkcs7_encrypted_data");

  my $bag_attributes = @$bags[0]->{bag_attributes};

  is(keys %$bag_attributes, 1, "Two bag attributes in bag");
  foreach my $attribute (keys %$bag_attributes) {
        like($bag_attributes->{localKeyID}, qr/CF 6B 1F EF D7 B4 D2 96 04 94 60 F6 29 16 75 3A E3 C8 5D 9F/, "localKeyID matches") if $attribute eq "localKeyID";
 }

  my $parameters = $info_hash->{pkcs7_encrypted_data}[$i]->{parameters};
  like($parameters->{iteration}, qr/2048/, "pkcs7_data parameters iteration matches");
  like($parameters->{nid_long_name}, qr/PBKDF2/, "pkcs7_data parameters nid_long_name matches");
  like($parameters->{nid_short_name}, qr/PBKDF2/, "pkcs7_bag parameters nid_short_name matches");

  like(@$bags[0]->{cert}, qr/CERTIFICATE/, "pkcs7_encrypted_data found certificate");
  like(@$bags[0]->{cert}, qr/1UEChMYSW50ZXJuZXQgV2lkZ2l0cyBQd/, "pkcs7_encrypted_data key matches");
  like(@$bags[0]->{type}, qr/certificate_bag/, "pkcs7_encrypted_data bag type matches");

  like(@$bags[0]->{issuer}, qr/C = AU, ST = Some-State, O = Internet Widgits Pty Ltd, CN = subinterCA/, "pkcs7_encrypted_data issuer matches");
  like(@$bags[0]->{subject}, qr/C = AU, ST = Some-State, O = Internet Widgits Pty Ltd, CN = leaf/, "pkcs7_encrypted_data subject matches");
  $bag_attributes = @$bags[0]->{bag_attributes};
  is(keys %$bag_attributes, 1, "Zero bag attributes in bag");

  like(@$bags[1]->{cert}, qr/CERTIFICATE/, "pkcs7_encrypted_data found certificate");
  like(@$bags[1]->{cert}, qr/lckNBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8/, "pkcs7_encrypted_data key matches");
  like(@$bags[1]->{type}, qr/certificate_bag/, "pkcs7_encrypted_data bag type matches");

  like(@$bags[1]->{issuer}, qr/C = AU, ST = Some-State, O = Internet Widgits Pty Ltd, CN = interCA/, "pkcs7_encrypted_data issuer matches");
  like(@$bags[1]->{subject}, qr/C = AU, ST = Some-State, O = Internet Widgits Pty Ltd, CN = subinterCA/, "pkcs7_encrypted_data subject matches");
  $bag_attributes = @$bags[1]->{bag_attributes};
  is(keys %$bag_attributes, 0, "Zero bag attributes in bag");

  like(@$bags[2]->{cert}, qr/CERTIFICATE/, "pkcs7_encrypted_data found certificate");
  like(@$bags[2]->{cert}, qr/SqlRVOCQine5c6ACSd0HUEjYy9aObqY47ySNULbz/, "pkcs7_encrypted_data key matches");
  like(@$bags[2]->{type}, qr/certificate_bag/, "pkcs7_encrypted_data bag type matches");

  like(@$bags[2]->{issuer}, qr/C = AU, ST = Some-State, O = Internet Widgits Pty Ltd, CN = rootCA/, "pkcs7_encrypted_data issuer matches");
  like(@$bags[2]->{subject}, qr/C = AU, ST = Some-State, O = Internet Widgits Pty Ltd, CN = interCA/, "pkcs7_encrypted_data subject matches");
  $bag_attributes = @$bags[2]->{bag_attributes};
  is(keys %$bag_attributes, 0, "Zero bag attributes in bag");

  like(@$bags[3]->{cert}, qr/CERTIFICATE/, "pkcs7_encrypted_data found certificate");
  like(@$bags[3]->{cert}, qr/aMFYxCzAJBgNVBAYTAkFVMRMwEQYDVQQ/, "pkcs7_encrypted_data key matches");
  like(@$bags[3]->{type}, qr/certificate_bag/, "pkcs7_encrypted_data bag type matches");

  like(@$bags[3]->{issuer}, qr/C = AU, ST = Some-State, O = Internet Widgits Pty Ltd, CN = rootCA/, "pkcs7_encrypted_data issuer matches");
  like(@$bags[3]->{subject}, qr/C = AU, ST = Some-State, O = Internet Widgits Pty Ltd, CN = rootCA/, "pkcs7_encrypted_data subject matches");
  $bag_attributes = @$bags[3]->{bag_attributes};
  is(keys %$bag_attributes, 0, "Zero bag attributes in bag");
}
done_testing;
