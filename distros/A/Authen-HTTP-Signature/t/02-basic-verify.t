use 5.010;

use Test::More tests => 4;
use Test::Fatal;

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

my $public_str = <<_EOT;
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDCFENGw33yGihy92pDjZQhl0C3
6rPJj+CvfSC8+q28hxA161QFNUd13wuCTUcq0Qd2qsBe/2hFyc2DCJJg0h1L78+6
Z4UMR7EOcpfdUE9Hf3m/hs+FUR45uBJeDK1HSFHD8bHKD6kv8FPGfJTotc+2xjJw
oYi+1hqp1fIekaxsyQIDAQAB
-----END PUBLIC KEY-----
_EOT

use Authen::HTTP::Signature::Parser;
use HTTP::Request;

my $req = HTTP::Request->parse($reqstr);
$req->header(Authorization => $default);

my $exception = exception { Authen::HTTP::Signature::Parser->new($req)->parse() };
like($exception, qr/skew/, "clock skew error");

my $pr = Authen::HTTP::Signature::Parser->new(
    skew => 0,
);

my $p = $pr->parse($req);

isa_ok($p, 'Authen::HTTP::Signature', 'parsed request');

$p->key($public_str);
is($p->verify(), 1, 'default verify successful');

$req->header( Authorization => $all );

$p = $pr->parse($req);
$p->key($public_str);
is($p->verify(), 1, 'all verify successful');

