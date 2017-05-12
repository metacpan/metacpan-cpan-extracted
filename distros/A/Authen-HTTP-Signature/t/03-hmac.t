use 5.010;

use Test::More tests => 9;

my $reqstr = <<_EOT;
POST /foo?param=value&pet=dog HTTP/1.1
Host: example.com
Content-Type: application/json
Content-MD5: Sd/dVLAcvNLSq16eXua5uQ==
Content-Length: 18

{"hello": "world"}
_EOT

## Inlined from UUID::Random by Moritz Onken
##
## This is fine for testing, but please use something 
## like Data::UUID::LibUUID in production code for
## much better randomness in UUID generation.

sub generate {
  my @chars = ('a'..'f',0..9);
  my @string;
  push(@string, $chars[int(rand(16))]) for(1..32);
  splice(@string,8,0,'-');
  splice(@string,13,0,'-');
  splice(@string,18,0,'-');
  splice(@string,23,0,'-');
  return join('', @string);
}

my $key = generate();

diag "Key is $key";

use Authen::HTTP::Signature;
use Authen::HTTP::Signature::Parser;
use HTTP::Request;

my $req = HTTP::Request->parse($reqstr);

my $default_auth = Authen::HTTP::Signature->new(
    key => $key,
    request => $req,
    key_id => 'unit',
    algorithm => 'hmac-sha1',
);

isa_ok($default_auth, 'Authen::HTTP::Signature', 'constructed object');
my $signed_req = $default_auth->sign();
is(!(!($signed_req->header('Authorization'))), 1, 'has hmac default auth header');
diag $signed_req->header('date');
diag $signed_req->header('authorization');
## test for existence

my $verify1 = Authen::HTTP::Signature::Parser->new(
    request => $signed_req,
);

my $default_verify = $verify1->parse();

isa_ok($default_verify, 'Authen::HTTP::Signature', 'constructed default verify obj');
$default_verify->key($key);

is($default_verify->verify(), 1, 'default hmac-sha1 verified successfully');

my $all_auth = Authen::HTTP::Signature->new(
    key => $key,
    request => $req,
    key_id => 'unit',
    headers => [qw(request-line host date content-type content-md5 content-length)],
    algorithm => 'hmac-sha256',
);

my $sign2 = $all_auth->sign();
is(!(!($sign2->header('Authorization'))), 1, 'has hmac all auth header');
diag $sign2->header('date');
diag $sign2->header('authorization');

my $verify2 = Authen::HTTP::Signature::Parser->new($sign2);

my $all_verify = $verify2->parse();

isa_ok($all_verify, 'Authen::HTTP::Signature', 'constructed all verify obj');
$all_verify->key($key);

is($all_verify->verify(), 1, 'all hmac-sha1 verified successfully');

my $other_key = generate();

diag "Other key is $other_key";

$default_verify->key($other_key);
isnt($default_verify->verify(), 1, 'bad hmac key with default failed');

$all_verify->key($other_key);
isnt($all_verify->verify(), 1, 'bad hmac key with all hdrs failed');


