use 5.010;

use Test::More tests => 3;

my $reqstr = <<_EOT;
POST /foo?param=value&pet=dog HTTP/1.1
Host: example.com
Date: Thu, 05 Jan 2012 21:31:40 GMT
Content-Type: application/json
Content-MD5: Sd/dVLAcvNLSq16eXua5uQ==
Content-Length: 18

{"hello": "world"}
_EOT

my $default = q{Signature keyId="Test",algorithm="rsa-sha256",signature="ATp0r26dbMIxOopqw0OfABDT7CKMIoENumuruOtarj8n/97Q3htHFYpH8yOSQk3Z5zh8UxUym6FYTb5+A0Nz3NRsXJibnYi7brE/4tx5But9kkFGzG+xpUmimN4c3TMN7OFH//+r8hBf7BT9/GmHDUVZT2JzWGLZES2xDOUuMtA="};
my $all = q{Signature keyId="Test",algorithm="rsa-sha256",headers="request-line host date content-type content-md5 content-length",signature="NSgN91rEJ7F0W2YjD1iT1FawHJVet2VWctBs7o283TSsPA75kCaUVo2JlnbFqJ5mNs0Dx+mexF1kS/7qaDcS4ht5UXvEG+DDB2x75WuTW62Q6wEVmpxmR92zNkBCMWouN7vB9kbx9BdtUqoeyPEZHH1TMLLrFUBQKt2yR2JKoB8="};
my $private_str = <<_EOT;
-----BEGIN RSA PRIVATE KEY-----
MIICXgIBAAKBgQDCFENGw33yGihy92pDjZQhl0C36rPJj+CvfSC8+q28hxA161QF
NUd13wuCTUcq0Qd2qsBe/2hFyc2DCJJg0h1L78+6Z4UMR7EOcpfdUE9Hf3m/hs+F
UR45uBJeDK1HSFHD8bHKD6kv8FPGfJTotc+2xjJwoYi+1hqp1fIekaxsyQIDAQAB
AoGBAJR8ZkCUvx5kzv+utdl7T5MnordT1TvoXXJGXK7ZZ+UuvMNUCdN2QPc4sBiA
QWvLw1cSKt5DsKZ8UETpYPy8pPYnnDEz2dDYiaew9+xEpubyeW2oH4Zx71wqBtOK
kqwrXa/pzdpiucRRjk6vE6YY7EBBs/g7uanVpGibOVAEsqH1AkEA7DkjVH28WDUg
f1nqvfn2Kj6CT7nIcE3jGJsZZ7zlZmBmHFDONMLUrXR/Zm3pR5m0tCmBqa5RK95u
412jt1dPIwJBANJT3v8pnkth48bQo/fKel6uEYyboRtA5/uHuHkZ6FQF7OUkGogc
mSJluOdc5t6hI1VsLn0QZEjQZMEOWr+wKSMCQQCC4kXJEsHAve77oP6HtG/IiEn7
kpyUXRNvFsDE0czpJJBvL/aRFUJxuRK91jhjC68sA7NsKMGg5OXb5I5Jj36xAkEA
gIT7aFOYBFwGgQAQkWNKLvySgKbAZRTeLBacpHMuQdl1DfdntvAyqpAZ0lY0RKmW
G6aFKaqQfOXKCyWoUiVknQJAXrlgySFci/2ueKlIE1QqIiLSZ8V8OlpFLRnb1pzI
7U1yQXnTAEFYM560yJlzUpOb1V4cScGd365tiSMvxLOvTA==
-----END RSA PRIVATE KEY-----
_EOT

use Authen::HTTP::Signature;
use HTTP::Request;

my $req = HTTP::Request->parse($reqstr);

my $default_auth = Authen::HTTP::Signature->new(
    key => $private_str,
    request => $req,
    key_id => 'Test',
);

isa_ok($default_auth, 'Authen::HTTP::Signature', 'constructed object');
my $signed_req = $default_auth->sign();
is($signed_req->header('Authorization'), $default, 'default auth header matches');

my $all_auth = Authen::HTTP::Signature->new(
    key => $private_str,
    request => $req,
    key_id => 'Test',
    headers => [qw(request-line host date content-type content-md5 content-length)],
);

my $sign2 = $all_auth->sign();
is($sign2->header('Authorization'), $all, 'all header matches');
