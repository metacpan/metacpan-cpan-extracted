use v5.24;
use experimental 'signatures';
use Test2::V0;
use FindBin '$Bin';
use lib "$Bin/../lib";
use AWS::Signature::V4;
use Digest::SHA qw< sha256_hex >;
use MIME::Base64 qw< encode_base64 >;

sub bad ($re = qr/./) {
   object { prop blessed => 'Ouch'; call code => 400; call message => match $re };
}

# Example from the AWS docs: presigned GET on S3
my $s3 = AWS::Signature::V4->new(
   service => 's3', region => 'us-east-1',
   credentials => {
      access_key_id     => 'AKIAIOSFODNN7EXAMPLE',
      secret_access_key => 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
   },
);
my $r = $s3->presign(
   url     => 'https://examplebucket.s3.amazonaws.com/test.txt',
   expires => 86400,
   time    => 1369353600,    # 20130524T000000Z
);
is $r->{signature},
   'aeeed9bbccd4d02ee5c0109b86d86835f995330da4c265957d157751f604d404',
   'signature matches AWS docs';
is $r->{url},
   'https://examplebucket.s3.amazonaws.com/test.txt'
   . '?X-Amz-Algorithm=AWS4-HMAC-SHA256'
   . '&X-Amz-Credential=AKIAIOSFODNN7EXAMPLE%2F20130524%2Fus-east-1%2Fs3%2Faws4_request'
   . '&X-Amz-Date=20130524T000000Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host'
   . '&X-Amz-Signature=aeeed9bbccd4d02ee5c0109b86d86835f995330da4c265957d157751f604d404',
   'full URL';
is $r->{headers}, {host => 'examplebucket.s3.amazonaws.com'}, 'headers to send';
like $r->{canonical_request}, qr/\nhost\nUNSIGNED-PAYLOAD\z/, 'S3: unsigned payload';

# other services: hash of the empty body, unless told otherwise
my $iam = AWS::Signature::V4->new(service => 'iam', region => 'us-east-1',
   credentials => {access_key_id => 'A', secret_access_key => 'S', session_token => 'TOK'});
$r = $iam->presign(url => 'https://iam.amazonaws.com/?Version=1&Action=X', time => 0);
like $r->{canonical_request},
   qr/\ne3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\z/,
   'non-S3: empty body hash';
like $r->{url}, qr{^https://iam\.amazonaws\.com/\?Action=X&Version=1&X-Amz-Algorithm=}, 'existing params kept';
like $r->{url}, qr/&X-Amz-Security-Token=TOK&/, 'session token goes in the query';
like $r->{url}, qr/&X-Amz-Signature=[0-9a-f]{64}\z/, 'signature is last';
unlike $r->{canonical_request}, qr/x-amz-security-token:/, 'not a header';

$r = $iam->presign(url => 'https://h/', unsigned_payload => 1, time => 0);
like $r->{canonical_request}, qr/\nUNSIGNED-PAYLOAD\z/, 'unsigned_payload';
my $abc = sha256_hex('abc');
$r = $iam->presign(url => 'https://h/', payload_hash => $abc, time => 0);
like $r->{canonical_request}, qr/\n$abc\z/, 'payload_hash';
$r = $iam->presign(url => 'https://h/', body => 'abc', method => 'put', time => 0);
like $r->{canonical_request}, qr/\APUT\n.*\nba7816bf/s, 'method and body hash';

# extra signed headers
$r = $iam->presign(url => 'https://h/', headers => {'Content-Type' => 'x/y'},
   signed_headers => ['content-type', 'host'], time => 0);
is $r->{signed_headers}, 'content-type;host', 'explicit signed headers';
like $r->{url}, qr/X-Amz-SignedHeaders=content-type%3Bhost/, 'encoded in the query';
is dies { $iam->presign(url => 'https://h/', signed_headers => ['nope']) },
   bad(qr/missing header/), 'missing header croaks';

# x-amz-* headers given are always signed, as AWS wants
$r = $s3->presign(url => 'https://b.s3.amazonaws.com/k', method => 'PUT', time => 0,
   headers => {'x-amz-acl' => 'public-read'});
is $r->{signed_headers}, 'host;x-amz-acl', 'x-amz-* header signed';
is $r->{headers}, {host => 'b.s3.amazonaws.com', 'x-amz-acl' => 'public-read'},
   'and to be sent';

# the payload hash: S3 takes UNSIGNED-PAYLOAD for granted, the others the hash
# of the body; anything else goes in a header, signed
$r = $s3->presign(url => 'https://b.s3.amazonaws.com/k', method => 'PUT', body => 'abc', time => 0);
like $r->{canonical_request}, qr/\n$abc\z/, 'S3 with a body: its hash';
is $r->{headers}{'x-amz-content-sha256'}, $abc, 'is sent in a header';
like $r->{signed_headers}, qr/\bx-amz-content-sha256\b/, 'which is signed';
$r = $s3->presign(url => 'https://b.s3.amazonaws.com/k', payload_hash => undef, time => 0);
like $r->{canonical_request}, qr/\nUNSIGNED-PAYLOAD\z/, 'undefined payload_hash is like missing';
is $r->{headers}, {host => 'b.s3.amazonaws.com'}, 'no header then';
$r = $iam->presign(url => 'https://h/', unsigned_payload => 1, time => 0);
is $r->{headers}{'x-amz-content-sha256'}, 'UNSIGNED-PAYLOAD', 'non-S3 unsigned payload: header';
$r = $iam->presign(url => 'https://h/', body => 'abc', time => 0);
ok !exists $r->{headers}{'x-amz-content-sha256'}, 'non-S3 body hash: no header';

# the path is sent as it is signed
$r = $s3->presign(url => 'https://b.s3.amazonaws.com/my file.txt', time => 0);
like $r->{url}, qr{\Ahttps://b\.s3\.amazonaws\.com/my%20file\.txt\?}, 'space encoded in the url';
like $r->{canonical_request}, qr{\A GET\n/my%20file\.txt\n}x, 'as it is signed';

# validation
is dies { $iam->presign(url => 'https://h/', expires => 0) }, bad(qr/expires/), 'expires 0';
is dies { $iam->presign(url => 'https://h/', expires => 604801) }, bad(qr/expires/), 'expires too long';
is dies { $iam->presign(url => 'https://h/', expires => 'x') }, bad(qr/expires/), 'expires not a number';
ok lives { $iam->presign(url => 'https://h/', expires => 604800) }, 'expires max';
is dies { $iam->presign(url => 'https://h/?X-Amz-Signature=x') }, bad(qr/X-Amz-Signature/),
   'already signed';
is dies { $iam->presign(url => 'https://h/ሴ') }, bad(qr/ASCII/), 'non-ASCII url';
is dies { $iam->presign }, bad(qr/"url"/), 'no url';
is dies { $iam->presign(url => 'https://h/', expires_in => 60) },
   bad(qr/unsupported for presign: "expires_in"/), 'misspelled expires';
for my $name (qw< checksum trailers decoded_content_length streaming >) {
   is dies { $iam->presign(url => 'https://h/', $name => 1) },
      bad(qr/unsupported for presign: "$name"/), "$name refused";
}
is dies { $s3->presign(url => 'folder/file.txt', headers => {Host => 'b.s3.amazonaws.com'}) },
   bad(qr{start with "/"}), 'relative path';
is dies { $iam->presign(url => 'https://h/', payload_hash => "x\r\nX: 1") },
   bad(qr/payload_hash/), 'invalid payload_hash';
is dies { $iam->presign(url => 'https://h/', method => "GET\n/x") }, bad(qr/method/),
   'invalid method';
is $iam->presign({url => 'https://h/', time => 0})->{signature},
   $iam->presign(url => 'https://h/', time => 0)->{signature}, 'hash reference of arguments';

# X.509 variant, with a stub signer
my $cert = "-----BEGIN CERTIFICATE-----\n" . encode_base64("\x30\x03\x02\x01\x07")
   . "-----END CERTIFICATE-----\n";
my $seen = '';
my $x = AWS::Signature::V4->new(service => 'rolesanywhere', region => 'r', x509 => {
      key_type  => 'RSA', certificate => $cert, serial => 42,
      chain => [$cert], signer => sub { $seen = shift; 'SIG' }});
$r = $x->presign(url => 'https://h/x', time => 0);
is $seen, $r->{string_to_sign}, 'signer got the string to sign';
is $r->{signature}, unpack('H*', 'SIG'), 'signature is the hex of the signer output';
like $r->{url}, qr/X-Amz-Algorithm=AWS4-X509-RSA-SHA256/, 'x509 algorithm';
like $r->{url}, qr{X-Amz-Credential=42%2F19700101%2Fr%2Frolesanywhere%2Faws4_request}, 'serial in credential';
my $enc = 'MAMCAQc%3D';    # base64 of the certificate, percent-encoded
like $r->{url}, qr/&X-Amz-X509=\Q$enc\E&/, 'certificate in the query';
like $r->{url}, qr/&X-Amz-X509-Chain=\Q$enc\E&/, 'chain in the query';
unlike $r->{canonical_request}, qr/^x-amz-x509/m, 'not headers';
like $r->{canonical_request}, qr/X-Amz-X509=/, 'signed as query parameters';

done_testing;
