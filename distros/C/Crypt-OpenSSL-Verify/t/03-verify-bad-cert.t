use Test::More;
use Crypt::OpenSSL::Verify;
use Crypt::OpenSSL::X509;

my $v = Crypt::OpenSSL::Verify->new('t/cacert.pem');
isa_ok($v, 'Crypt::OpenSSL::Verify');

my $text =<<CERT;
-----BEGIN CERTIFICATE-----
MIIEGDCCA4GgAwIBAgIBAjANBgkqhkiG9w0BAQUFADAcMQswCQYDVQQGEwJVSzEN
MAsGA1UEAxMEdGVzdDAeFw0wNzA3MDExMzQyNTRaFw0wODA2MzAxMzQyNTRaMCMx
CzAJBgNVBAYTAlVLMRQwEgYDVQQDFAtURVNUX0NMSUVOVDCCAiIwDQYJKoZIhvcN
AQEBBQADggIPADCCAgoCggIBAOnYoi4lwo+Nj+MX1hmNlWXfXIyOLKlY0uAcF7zm
lH8RG6XjMOsA19g71jyfHYuNfR+aQXTPgJ+B2Nnyr9EUF3XUuNKrmDaM4jtiqBZJ
RRiNmfwlWfcdlyTUPXSDu3s2II7wteCcOiHo20jMwSvRo1SFpOLCixnn1UYeA/Ni
cdWgVCNGuMOKAdK200CpWR2VnHIUvJ6uWz8zjhV9iiB6La7uqkf/9xmyNh8zUb/q
nqi5HXY0ygLscgoFfSfu/TLJ/8OjLkA7PaHQ4zYb9AmBJQJChwb9DOZ9CcKxOkxG
IuOPInxFoTUdoHWRgfskAMnBHt49NXKKYRejk6hne1y0cvpSqq4TXF9/VvKravug
obumQU5MAFGW/UTTHaAx9vruu6JGPzDLzpMrFUXFJybcZgsTe3KKpYnosnpMzuhn
XmSRyfJySJquVY+5LuivwkRCUSJsA1NgvIEatm7EkQzHYh1S5vcckd8jXRzHGz70
zoV6z1JVIWoOa1riXj6ebs79+x1WFH4y/X6l3JQNB00BE5YNqemp+UBafnGXxKfH
L2E/U/LfV8lKycFyIiPgvsxcI+b5IUh2tjT8MmCV7XvwDksvvOQv3qKIA+4Sr3g3
lf4t81ncM5lxtLrwcHCc/H48bpinKq9UyliLt5ZItCp75QBNAB1qnFkjUspeigDM
KYMDAgMBAAGjgd4wgdswCQYDVR0TBAIwADARBglghkgBhvhCAQEEBAMCBLAwKwYJ
YIZIAYb4QgENBB4WHFRpbnlDQSBHZW5lcmF0ZWQgQ2VydGlmaWNhdGUwHQYDVR0O
BBYEFM1CNhwgAjgbKAwzClbJYUXAFBorMEwGA1UdIwRFMEOAFAG3g0vMcVpEHfe1
Yao0gpWJXAHLoSCkHjAcMQswCQYDVQQGEwJVSzENMAsGA1UEAxMEdGVzdIIJANQs
vM8fe7IuMAkGA1UdEgQCMAAwCQYDVR0RBAIwADALBgNVHQ8EBAMCBaAwDQYJKoZI
hvcNAQEFBQADgYEACgl1sxEPVgsK8sTYCF+OhTIrZ5fhhmCf5kunCWvLeMcTJtNP
1kwCVlDz8GhYVQOnhy5fPzjKE/G6JB7H8s2MioNtW265H2xRQx0FlO/eldqNTqRC
7TAJ6y/TH2zA3Y7IvJWpvLBVRp3bEClyXM9WJH9x7ByHGGly6OWKwWUc1QQ=
-----END CERTIFICATE-----
CERT

my $cert = Crypt::OpenSSL::X509->new_from_string($text);
isa_ok($cert, 'Crypt::OpenSSL::X509');

my $ret;
eval {
        $ret = $v->verify($cert);
};
ok($@ =~ /(verify: certificate has expired)|(verify: unable to get local)|(verify: unknown certificate)/);
ok(!$ret);

$v = Crypt::OpenSSL::Verify->new(
    't/cacert.pem',
    {
    CApath => '/etc/ssl/certs',
    noCAfile => 0,
}
    );
isa_ok($v, 'Crypt::OpenSSL::Verify');

$ret = undef;
eval {
        $ret = $v->verify($cert);
};
ok($@ =~ /(verify: certificate has expired)|(verify: unable to get local)|(verify: unknown certificate)/);
ok(!$ret);

done_testing;
