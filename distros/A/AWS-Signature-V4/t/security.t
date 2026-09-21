use v5.24;
use Test2::V0;
use FindBin '$Bin';
use lib "$Bin/../lib";
use experimental 'signatures';
use Data::Dumper ();
use File::Temp ();
use AWS::Signature::V4;

my %cred = (access_key_id => 'AKID', secret_access_key => 'SECRET');
my $s3  = AWS::Signature::V4->new(service => 's3', region => 'r', credentials => {%cred});
my $url = 'https://b.s3.amazonaws.com/k';

sub bad_request ($re) {
   object { prop blessed => 'Ouch'; call code => 400; call message => match $re };
}

sub dump_of ($x) {
   local $Data::Dumper::Deparse = 0;
   Data::Dumper->new([$x])->Useqq(1)->Dump;
}

subtest 'header names and values are validated' => sub {
   for my $value ("a\r\nX-Injected: 1", "a\nb", "a\rb", "a\0b") {
      my $shown = $value =~ s/([^ -~])/sprintf '\\x%02X', ord $1/ger;
      is dies { $s3->sign(method => 'GET', url => $url, headers => {'X-V' => $value}) },
         bad_request(qr/header/), "value $shown rejected";
   }
   for my $name ("x-n:1\nfoo", 'x n', 'x:n', '', "x\x{e9}") {
      my $shown = $name =~ s/([^ -~])/sprintf '\\x%02X', ord $1/ger;
      is dies { $s3->sign(method => 'GET', url => $url, headers => {$name => 'v'}) },
         bad_request(qr/header/), "name '$shown' rejected";
   }
   ok lives { $s3->sign(method => 'GET', url => $url,
      headers => {"X-Ok_1.a!#\$%&'*+^`|~" => "tab\there, spaces  ok"}) },
      'valid token names and values with tabs and spaces are fine';
   is dies { $s3->presign(url => $url, headers => {'X-V' => "a\nb"}) },
      bad_request(qr/header/), 'presign too';
};

subtest 'the derived signing key is not exposed' => sub {
   my $r = $s3->sign(method => 'PUT', url => $url, time => 0,
      streaming => 1, decoded_content_length => 1);
   my $ck = $r->{chunker};
   ok !$ck->can('key'), 'no key accessor';
   ok !$ck->can('previous'), 'no previous accessor';
   my $key = unpack 'H*', AWS::Signature::V4::Credentials->new(%cred)
      ->signing_key($r->{scope});
   unlike dump_of($r), qr/\Q$key\E/, 'the hex key is not in a dump of the result';
   my $raw = pack 'H*', $key;
   unlike dump_of($r), qr/\Q@{[ quotemeta $raw ]}\E/, 'nor the raw key';
   like $ck->chunk('x'), qr/\A1;chunk-signature=[0-9a-f]{64}\r\nx\r\n\z/, 'chunks are still signed';
};

subtest 'presign refuses authentication parameters in the url' => sub {
   for my $param (qw<
      X-Amz-Algorithm X-Amz-Credential X-Amz-Date X-Amz-Expires
      X-Amz-SignedHeaders X-Amz-Signature X-Amz-Security-Token
      X-Amz-X509 X-Amz-X509-Chain x-amz-signature X-AMZ-EXPIRES
   >) {
      is dies { $s3->presign(url => "$url?$param=1") },
         bad_request(qr/\Q$param\E/i), "$param rejected";
   }
   is dies { $s3->presign(url => "$url?X%2DAmz%2DCredential=1") },
      bad_request(qr/credential/i), 'also when percent-encoded';
   ok lives { $s3->presign(url => "$url?X-Amz-Meta-Foo=1&versionId=3") },
      'other parameters are fine';
};

subtest 'host is always signed' => sub {
   my $r = $s3->sign(method => 'GET', url => $url, time => 0,
      signed_headers => ['x-amz-date']);
   is $r->{signed_headers}, 'host;x-amz-content-sha256;x-amz-date',
      'sign adds host, and the x-amz-* headers';
   $r = $s3->presign(url => $url, time => 0, signed_headers => ['x-amz-date'],
      headers => {'x-amz-date' => 'x'});
   is $r->{signed_headers}, 'host;x-amz-date', 'presign adds host';
};

subtest 'secrets of the x509 key are not kept around' => sub {
   my $dir = File::Temp::tempdir(CLEANUP => 1);
   system(qq{openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 }
      . qq{-aes256 -pass pass:TopSecretPass -out $dir/k.pem 2>/dev/null}) == 0
      or skip_all 'openssl needed';
   system(qq{openssl req -new -x509 -key $dir/k.pem -passin pass:TopSecretPass }
      . qq{-subj /CN=t -days 1 -out $dir/c.pem 2>/dev/null}) == 0
      or skip_all 'openssl needed';
   my $pem = do { local (@ARGV, $/) = "$dir/k.pem"; <> };
   my $s = AWS::Signature::V4->new(service => 'rolesanywhere', region => 'r',
      x509 => {key_type => 'ECDSA', certificate_file => "$dir/c.pem",
               private_key => $pem, private_key_password => 'TopSecretPass'});
   ok !exists $s->x509->{private_key}, 'no key text in ->x509';
   ok !exists $s->x509->{private_key_password}, 'no password in ->x509';
   my $dump = dump_of($s);
   unlike $dump, qr/TopSecretPass/, 'no password in a dump';
   unlike $dump, qr/ENCRYPTED PRIVATE KEY/, 'no key text in a dump';
   like $s->sign(method => 'GET', url => 'https://h/', time => 0)->{signature},
      qr/\A[0-9a-f]+\z/, 'signing still works';
};

subtest 'userinfo in the url is refused' => sub {
   for my $u ('http://a@evil.example@good.example/', 'http://user@good.example/') {
      is dies { $s3->sign(method => 'GET', url => $u) }, bad_request(qr/user/), $u;
   }
};

subtest 'caller input is escaped in error messages' => sub {
   for my $case (
      [sub { AWS::Signature::V4->new(service => 's', region => 'r',
         x509 => {key_type => "DSA\nFAKE LOG LINE"}) }, 'key_type'],
      [sub { $s3->sign(method => 'PUT', url => $url, streaming => 1,
         decoded_content_length => 1, checksum => "md5\nFAKE") }, 'checksum'],
      [sub { $s3->sign(method => 'PUT', url => $url, streaming => 1,
         decoded_content_length => 1, trailers => ["x\nFAKE"]) }, 'trailer name'],
      [sub { $s3->sign(method => 'GET', url => $url, signed_headers => ["x\nFAKE"]) },
         'signed header name'],
      [sub { AWS::Signature::V4->new(service => 's', region => 'r',
         x509 => {key_type => 'RSA', certificate => "\x30\x03\x02\x01\x05", serial => 1,
            private_key_file => "/no/such\nFAKE LOG LINE"}) }, 'private key file'],
      [sub { AWS::Signature::V4->new(service => 's', region => 'r',
         x509 => {key_type => 'RSA', certificate_file => "/no/such\nFAKE LOG LINE",
            serial => 1, signer => sub { 'x' }}) }, 'certificate file'],
   ) {
      my ($code, $name) = @$case;
      my $e = dies { $code->() };
      isa_ok $e, ['Ouch'], $name;
      unlike $e->message, qr/[\r\n]/, "$name: no line breaks in the message";
   }
};

done_testing;
