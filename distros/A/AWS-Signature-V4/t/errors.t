use v5.24;
use Test2::V0;
use FindBin '$Bin';
use lib "$Bin/../lib";
use experimental 'signatures';
use Digest::SHA qw< sha256 >;
use MIME::Base64 qw< encode_base64 >;
use AWS::Signature::V4;
use AWS::Signature::V4::Chunker;

my %cred = (credentials => {access_key_id => 'a', secret_access_key => 'b'});
my $s = AWS::Signature::V4->new(service => 's3', region => 'r', %cred);
my $secret = 'Hunter2-TopSecret';

sub ouch_like ($code, $status, $name) {
   is dies { $code->() },
      object { prop blessed => 'Ouch'; call code => $status },
      $name;
}

sub streaming ($signer, %opts) {
   $signer->sign(method => 'PUT', url => 'http://h/', streaming => 1, %opts);
}

# errors caused by the caller are Ouch exceptions with code 400
my %caller = (
   'no service'      => sub { AWS::Signature::V4->new(region => 'r', %cred) },
   'no region'       => sub { AWS::Signature::V4->new(service => 's', %cred) },
   'no credentials'  => sub { AWS::Signature::V4->new(service => 's', region => 'r') },
   'both variants'   => sub { AWS::Signature::V4->new(service => 's', region => 'r', %cred, x509 => {}) },
   'bad key type'   => sub { AWS::Signature::V4->new(service => 's', region => 'r', x509 => {key_type => 'DSA'}) },
   'x509 key type under its old name' =>
      sub { AWS::Signature::V4->new(service => 's', region => 'r', x509 => {algorithm => 'RSA'}) },
   'credentials not a hash' =>
      sub { AWS::Signature::V4->new(service => 's', region => 'r', credentials => 'AKID:SECRET') },
   'no method'       => sub { $s->sign(url => 'http://h/') },
   'non-ASCII url'   => sub { $s->sign(method => 'GET', url => "http://h/\x{e9}") },
   'control chars in url' => sub { $s->sign(method => 'GET', url => "http://h/a\nb") },
   'empty url'       => sub { $s->sign(method => 'GET', url => '') },
   'no host'         => sub { $s->presign(url => '/path') },
   'wide body'       => sub { $s->sign(method => 'PUT', url => 'http://h/', body => "\x{263a}") },
   'body_fh not a handle' => sub { $s->sign(method => 'PUT', url => 'http://h/', body_fh => 'file.txt') },
   'bad expires'     => sub { $s->presign(url => 'http://h/', expires => 0) },
   'unknown checksum' => sub { streaming($s, decoded_content_length => 1, checksum => 'md5') },
   'finish twice'    => sub {
      my $ck = streaming($s, decoded_content_length => 0)->{chunker};
      $ck->finish;
      $ck->finish;
   },
);
ouch_like $caller{$_}, 400, $_ for sort keys %caller;

# ... including what goes wrong when loading certificates and keys
my %x509 = (service => 's', region => 'r');
my $der = "\x30\x03\x02\x01\x05";    # a tiny, valid, DER structure
my %x509_errors = (
   'garbage certificate' => {key_type => 'RSA', certificate => 'garbage', serial => 1, signer => sub { 'x' }},
   'truncated certificate' => {key_type => 'RSA', certificate => "\x30\x82\x01", signer => sub { 'x' }},
   'signer not code' => {key_type => 'RSA', certificate => $der, serial => 1, signer => 'nope'},
   'missing key file' => {key_type => 'RSA', certificate => $der, serial => 1, private_key_file => '/no/such/key'},
   'garbage key' => {key_type => 'ECDSA', certificate => $der, serial => 1, private_key => 'garbage'},
);
for my $name (sort keys %x509_errors) {
   ouch_like sub { AWS::Signature::V4->new(%x509, x509 => $x509_errors{$name}) }, 400, $name;
}

# internal problems are 500
ouch_like sub { AWS::Signature::V4::Chunker->new(signed => 1, expected => 0) }, 500,
   'chunker without key';

# the error is reported where the caller is, and holds no secrets
my $e = dies {
   AWS::Signature::V4->new(%x509, x509 => {
      key_type => 'RSA', certificate => $der, serial => 1,
      private_key => 'garbage', private_key_password => $secret,
   });
};
like "$e", qr{ at \S*errors\.t line \d+}, 'error reported at the line of the caller';
unlike $e->trace, qr{\Q$secret\E}, 'the trace does not include the password';
unlike "$e", qr{\Q$secret\E}, 'the message does not include the password';
for my $how ('verbose', 'die handler') {
   my $e = dies {
      local $Carp::Verbose = $how eq 'verbose';
      local $SIG{__DIE__} = sub { die Carp::longmess($_[0]) } if $how eq 'die handler';
      AWS::Signature::V4->new(%x509, x509 => {
         key_type => 'RSA', certificate => $der, serial => 1,
         private_key => 'garbage', private_key_password => $secret,
      });
   };
   like $e->message, qr{\Acannot load the private key: [^\n]+\z},
      "$how: the message is one line";
   unlike "$e", qr{\Q$secret\E}, "$how: the message does not include the password";
}
like dies { $s->sign(url => 'http://h/') }, qr{ at \S*errors\.t line \d+},
   'same for the errors of sign';

# options: undefined is like missing, derived values cannot be set
my $t = AWS::Signature::V4->new(
   service => 's3', region => 'r', %cred,
   payload_header => undef, double_encode => undef, normalize_path => undef,
);
ok $t->payload_header, 'undefined payload_header: default for s3';
ok !$t->double_encode, 'undefined double_encode: default for s3';
ok !$t->normalize_path, 'undefined normalize_path: default for s3';
like $t->sign(method => 'GET', url => 'http://h/')->{headers},
   {'x-amz-content-sha256' => qr/\A[0-9a-f]{64}\z/}, 'the header is there';

my $u = AWS::Signature::V4->new(
   service => 's', region => 'r', %cred,
   algorithm => 'RSA', _signer => undef, _x509_serial => 'X',
);
is $u->algorithm, 'AWS4-HMAC-SHA256', 'algorithm cannot be set';

my %mine = (access_key_id => 'a', secret_access_key => 'b');
my $v = AWS::Signature::V4->new(service => 's', region => 'r', credentials => \%mine);
$mine{access_key_id} = 'EVIL';
is $v->credentials->{access_key_id}, 'a', 'credentials are copied';

# a subclass can assign $_ in its builders
{
   package Sub::Signer;
   use Moo;
   extends 'AWS::Signature::V4';
   has '+region' => (lazy => 1, builder => 1);
   sub _build_region { $_ = 'eu-west-1'; return $_ }
}
is(Sub::Signer->new(service => 's', %cred)->region, 'eu-west-1', 'builders can use $_');

# no warnings for what used to be accepted silently
is warns { $s->sign(method => 'GET', url => 'http://h/', headers => {'X-Opt' => undef}) },
   0, 'undefined header value: no warnings';

# the chunker is not confused by its own errors
my $ck = streaming($s, decoded_content_length => 9, checksum => 'sha256',
   trailers => ['x-foo'], signed_headers => ['host'])->{chunker};
$ck->chunk('123456789');
ouch_like sub { $ck->finish }, 400, 'missing trailer value';
like $ck->finish('x-foo' => 1),
   qr{x-amz-checksum-sha256:\Q@{[ encode_base64(sha256('123456789'), '') ]}\E\r\n},
   'the checksum survives a failed finish';

$ck = streaming($s, decoded_content_length => 4)->{chunker};
$ck->chunk('abc');
ouch_like sub { $ck->chunk('xy') }, 400, 'too much data';
ok lives { $ck->chunk('x') }, 'a chunk that fits is still accepted';
ok lives { $ck->finish }, 'and the stream can be completed';

done_testing;
