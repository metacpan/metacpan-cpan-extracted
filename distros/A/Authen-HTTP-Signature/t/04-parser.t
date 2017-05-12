use 5.010;

use strict;
use warnings;

use Test::More tests => 12;
use Test::Fatal;

my $reqstr = <<_EOT;
POST /foo?param=value&pet=dog HTTP/1.1
Host: example.com
Content-Type: application/json
Content-MD5: Sd/dVLAcvNLSq16eXua5uQ==
Content-Length: 18

{"hello": "world"}
_EOT

my $key = 'kweepa!';

my $invalid_hdr = q|Signature keyId="parser_test",algorithm="hmac-sha1",headers="request-line date foobar",signature="eQjZuLJsT/Uy05xjC4BXHC+UYBE==="|;
my $dup_hdr = q|Signature keyId="parser_test",algorithm="hmac-sha1",headers="request-line date date",signature="eQjZuLJsT/Uy05xjC4BXHC+UYBE==="|;
my $no_key_id = q|Signature keyId="",algorithm="hmac-sha1",headers="request-line date",signature="eQjZuLJsT/Uy05xjC4BXHC+UYBE==="|;
my $no_algo = q|Signature keyId="parser_test",algorithm="",headers="request-line date",signature="eQjZuLJsT/Uy05xjC4BXHC+UYBE==="|;
my $bogus_algo = q|Signature keyId="parser_test",algorithm="crap",headers="request-line date",signature="eQjZuLJsT/Uy05xjC4BXHC+UYBE==="|;
my $degenerate = q|Signature keyId="fo,o",algorithm="hmac-sha1",headers="rEQUest-LiNe dATe",signature="eQjZuLJsT/Uy05xjC4BXHC+UYBE==="|;
my $ext = q|Signature keyId="foo",algorithm="hmac-sha1",headers="request-line date",ext="foobar",signature="eQjZuLJsT/Uy05xjC4BXHC+UYBE==="|;

use Authen::HTTP::Signature;
use HTTP::Request;

my $req = HTTP::Request->parse($reqstr);

my $c = Authen::HTTP::Signature->new(
    key => $key,
    key_id => 'parser_test',
    request => $req,
    algorithm => 'hmac-sha1',
    headers => [qw(request-line date)],
);

my $sr = $c->sign();

use Authen::HTTP::Signature::Parser;

my $p = Authen::HTTP::Signature::Parser->new($sr);

isa_ok($p, 'Authen::HTTP::Signature::Parser', 'constructed parser');

my $missing_auth = $sr->clone;
$missing_auth->remove_header('authorization');

my $e = exception { Authen::HTTP::Signature::Parser->new($missing_auth)->parse(); };
like($e, qr/[Nn]o authorization header/, 'no auth header fails');

$missing_auth->header('authorization' => 'foobar');
$e = exception { Authen::HTTP::Signature::Parser->new($missing_auth)->parse(); };
like($e, qr/Signature/, 'missing Signature fails');

$missing_auth->header('authorization' => 'Signature keyId="foobar"');
$e = exception { Authen::HTTP::Signature::Parser->new($missing_auth)->parse(); };
like($e, qr/signature data/, 'missing signature data fails');

$missing_auth->header('authorization' => $invalid_hdr );
$e = exception { Authen::HTTP::Signature::Parser->new($missing_auth)->parse(); };
like($e, qr/Couldn\'t get/, 'invalid header fails');

$missing_auth->header('authorization' => $dup_hdr );
$e = exception { Authen::HTTP::Signature::Parser->new($missing_auth)->parse(); };
like($e, qr/[Dd]uplicate/, 'duplicate header fails');

$missing_auth->header('authorization' => $no_key_id );
$e = exception { Authen::HTTP::Signature::Parser->new($missing_auth)->parse(); };
like($e, qr/key id/, 'no key id fails');

$missing_auth->header('authorization' => $no_algo );
$e = exception { Authen::HTTP::Signature::Parser->new($missing_auth)->parse(); };
like($e, qr/No algo/, 'no algorithm fails');

$missing_auth->header('authorization' => $bogus_algo );
$e = exception { Authen::HTTP::Signature::Parser->new($missing_auth)->parse(); };
like($e, qr/supported/, 'bogus algorithm fails');

$missing_auth->header('authorization' => $degenerate );
$e = exception { Authen::HTTP::Signature::Parser->new($missing_auth)->parse(); };
is($e, undef, 'degenerate header parsed ok');

$missing_auth->header('authorization' => $ext );
my $q;
$e = exception { $q = Authen::HTTP::Signature::Parser->new($missing_auth)->parse(); };
is($e, undef, 'extension header parsed ok');
is($q->extensions, 'foobar', 'got extentsion content');
