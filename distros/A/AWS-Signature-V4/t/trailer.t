use v5.24;
use experimental 'signatures';
use Test2::V0;
use FindBin '$Bin';
use lib "$Bin/../lib";
use AWS::Signature::V4;
use Digest::SHA qw< sha1 sha256 sha256_hex hmac_sha256 hmac_sha256_hex >;
use MIME::Base64 qw< encode_base64 >;

my $s3 = AWS::Signature::V4->new(service => 's3', region => 'us-east-1', credentials => {
      access_key_id => 'AKIAIOSFODNN7EXAMPLE',
      secret_access_key => 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'});
my $x = AWS::Signature::V4->new(service => 's3', region => 'r', x509 => {
      key_type  => 'RSA', serial => 1, signer => sub { 'x' },
      certificate => "-----BEGIN CERTIFICATE-----\nMAMCAQc=\n-----END CERTIFICATE-----\n"});

sub bad ($re) {
   object { prop blessed => 'Ouch'; call code => 400; call message => match $re };
}

# the reference for the signed chunks and trailers
my $key = 'AWS4' . 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY';
$key = hmac_sha256($_, $key) for '20130524', 'us-east-1', 's3', 'aws4_request';
my $scope = '20130524/us-east-1/s3/aws4_request';
my $sts = sub ($kind, @parts) { join "\n", "AWS4-HMAC-SHA256-$kind", '20130524T000000Z', $scope, @parts };

sub start ($signer = $s3, %opts) {
   $signer->sign(method => 'PUT', url => 'https://h/k', time => 1369353600,
      decoded_content_length => 9, %opts);
}

# --- checksums, fed in two pieces
my %expect = (    # of "123456789"
   crc32  => encode_base64(pack('N', 0xCBF43926), ''),
   crc32c => encode_base64(pack('N', 0xE3069283), ''),
   sha1   => encode_base64(sha1('123456789'), ''),
   sha256 => encode_base64(sha256('123456789'), ''),
);
for my $algo (sort keys %expect) {
   my $ck = start($x, streaming => 'unsigned', checksum => $algo)->{chunker};
   my $body = $ck->chunk('1234') . $ck->chunk('56789') . $ck->finish;
   is $body, "4\r\n1234\r\n5\r\n56789\r\n0\r\nx-amz-checksum-$algo:$expect{$algo}\r\n\r\n",
      "unsigned, $algo, byte for byte";
}

# --- crc32c against a bitwise reference, on longer data and in many chunks
sub crc32c_ref ($data) {
   my $crc = 0xFFFFFFFF;
   for my $byte (unpack 'C*', $data) {
      $crc ^= $byte;
      $crc = ($crc & 1) ? (($crc >> 1) ^ 0x82F63B78) : ($crc >> 1) for 1 .. 8;
   }
   return encode_base64(pack('N', $crc ^ 0xFFFFFFFF), '');
}
my $long = join '', map { chr(($_ * 7) % 256) } 1 .. 5000;
my $ck = start($x, streaming => 'unsigned', checksum => 'crc32c',
   decoded_content_length => length $long)->{chunker};
$ck->chunk(substr($long, $_ * 1000, 1000)) for 0 .. 4;
like $ck->finish, qr/x-amz-checksum-crc32c:\Q${\ crc32c_ref($long)}\E\r\n/, 'crc32c on longer data';

# the test here will exercise whatever is available; we don't explicitly
# test the pure-perl version shipped with the module in case
# String::CRC32 is available. FIXME figure out how to do this withouth
# going back to using package variables.
for my $size (1 .. 9, 65535 .. 65537, 70001) {
   my $sum = AWS::Signature::V4::Checksum->new('crc32c');
   my $data = substr $long x 15, 0, $size;
   my ($head, $tail) = (substr($data, 0, $size / 3), substr($data, $size / 3));
   $sum->add(\$head)->add(\$tail);
   is $sum->base64, crc32c_ref($data), "crc32c, $size bytes";
}

# wide characters are refused by every algorithm, references to anything else
# than a defined string too; upgraded byte strings are fine
for my $algo (sort keys %expect) {
   my $sum = AWS::Signature::V4::Checksum->new($algo);
   is dies { $sum->add(\"\x{263a}") }, bad(qr/byte string/), "$algo: wide character refused";
   is dies { $sum->add('123') }, bad(qr/reference/), "$algo: not a reference";
   is dies { $sum->add(\undef) }, bad(qr/reference/), "$algo: undef";
   # stored as UTF-8, with bytes that differ from the characters: what is
   # summed must be the bytes, and the caller's string must not be touched
   my $raw = "\xe9\xff\x41" . '123456789';
   my $upgraded = $raw;
   utf8::upgrade($upgraded);
   is $sum->add(\$upgraded)->base64,
      AWS::Signature::V4::Checksum->new($algo)->add(\$raw)->base64,
      "$algo: upgraded byte string sums as bytes";
   # the digest modules may clear the UTF-8 flag of the scalar they are
   # given, but the string the caller sees must be the same one
   is $upgraded, $raw, "$algo: and the input string still holds those bytes";
}
{
   my $ck = start($x, streaming => 'unsigned', checksum => 'crc32c')->{chunker};
   is dies { $ck->chunk("\x{263a}") }, bad(qr/chunk must be a byte string/), 'unsigned crc32c chunker: wide character refused';
   is dies { $ck->chunk(['123456789']) }, bad(qr/reference to one/), 'chunk of an array reference';
   is dies { $ck->chunk(bless \my $o, 'Foo') }, bad(qr/reference to one/), 'chunk of an object';
   is $ck->chunk(\'123456789'), "9\r\n123456789\r\n", 'and a scalar reference is fine';
   like $ck->finish, qr/x-amz-checksum-crc32c:\Q$expect{crc32c}\E\r\n/, 'the refused pieces were not counted';
}

# --- request side
my $r = start($x, streaming => 'unsigned', checksum => 'crc32c');
is $r->{headers}{'x-amz-content-sha256'}, 'STREAMING-UNSIGNED-PAYLOAD-TRAILER', 'unsigned marker';
is $r->{headers}{'x-amz-trailer'}, 'x-amz-checksum-crc32c', 'x-amz-trailer';
like $r->{signed_headers}, qr/x-amz-trailer/, 'and it is signed';
is $r->{headers}{'x-amz-decoded-content-length'}, 9, 'decoded length';
is $r->{headers}{'content-encoding'}, 'aws-chunked', 'content encoding';
ok !defined $r->{chunker}->_mac, 'unsigned chunker has no key';

$r = start($s3, streaming => 'signed', checksum => 'sha256');
ok !(grep { defined && !ref && ($_ eq $key || $_ eq unpack 'H*', $key) } values $r->{chunker}->%*),
   'signed chunker: the key is not in the object';
is $r->{headers}{'x-amz-content-sha256'}, 'STREAMING-AWS4-HMAC-SHA256-PAYLOAD-TRAILER', 'signed trailer marker';
$r = start($s3, streaming => 1);
is $r->{headers}{'x-amz-content-sha256'}, 'STREAMING-AWS4-HMAC-SHA256-PAYLOAD', 'no trailer: plain marker';
ok !exists $r->{headers}{'x-amz-trailer'}, 'and no x-amz-trailer';

# --- signed chunks and trailer, against a straightforward reimplementation
{
   my $r = start($s3, streaming => 'signed', checksum => 'crc32');
   my $prev = $r->{signature};

   my $sig1 = hmac_sha256_hex($sts->('PAYLOAD', $prev, sha256_hex(''), sha256_hex('123456789')), $key);
   my $sig2 = hmac_sha256_hex($sts->('PAYLOAD', $sig1, sha256_hex(''), sha256_hex('')), $key);
   my $line = "x-amz-checksum-crc32:$expect{crc32}";
   my $tsig = hmac_sha256_hex($sts->('TRAILER', $sig2, sha256_hex("$line\n")), $key);

   my $ck = $r->{chunker};
   is $ck->chunk('123456789'), "9;chunk-signature=$sig1\r\n123456789\r\n", 'signed chunk';
   is $ck->finish,
      "0;chunk-signature=$sig2\r\n$line\r\nx-amz-trailer-signature:$tsig\r\n\r\n",
      'final chunk, trailer and trailer signature';
}

# --- caller-supplied trailers
{
   my $r = start($x, streaming => 'unsigned', trailers => ['X-Amz-Checksum-Crc64nvme']);
   is $r->{headers}{'x-amz-trailer'}, 'x-amz-checksum-crc64nvme', 'declared, lowercased';
   my $ck = $r->{chunker};
   $ck->chunk('123456789');
   is $ck->finish('x-amz-checksum-crc64nvme' => 'AAAAAAAAAAA='),
      "0\r\nx-amz-checksum-crc64nvme:AAAAAAAAAAA=\r\n\r\n", 'value given at finish';

   $r = start($s3, streaming => 1, checksum => 'sha1', trailers => ['x-foo', 'x-bar']);
   is $r->{headers}{'x-amz-trailer'}, 'x-amz-checksum-sha1,x-foo,x-bar', 'built-in first, then declared';
   $ck = $r->{chunker};
   $ck->chunk('123456789');
   my $sig1 = hmac_sha256_hex($sts->('PAYLOAD', $r->{signature}, sha256_hex(''), sha256_hex('123456789')), $key);
   my $sig2 = hmac_sha256_hex($sts->('PAYLOAD', $sig1, sha256_hex(''), sha256_hex('')), $key);
   my @lines = ("x-amz-checksum-sha1:$expect{sha1}", 'x-foo:1', 'x-bar:2');
   my $tsig = hmac_sha256_hex($sts->('TRAILER', $sig2, sha256_hex(join '', map { "$_\n" } @lines)), $key);
   is $ck->finish('x-foo' => '1', 'x-bar' => '2'),
      "0;chunk-signature=$sig2\r\n" . join('', map { "$_\r\n" } @lines)
      . "x-amz-trailer-signature:$tsig\r\n\r\n",
      'all trailers, in order, signed';

   my $mk = sub ($signer = $x) {
      my $c = start($signer, streaming => $signer == $x ? 'unsigned' : 1, checksum => 'crc32',
         trailers => ['X-Foo'])->{chunker};
      $c->chunk('123456789');
      $c;
   };
   is dies { $mk->()->finish }, bad(qr/missing value for trailer 'x-foo'/), 'missing value';
   is dies { $mk->()->finish('x-foo' => 1, 'x-nope' => 2) }, bad(qr/undeclared trailers: x-nope/),
      'undeclared value';
   is dies { $mk->()->finish('x-foo' => 1, 'x-amz-checksum-crc32' => 'x') },
      bad(qr/'x-amz-checksum-crc32' is computed/), 'computed value given';
   is dies { $mk->()->finish('x-foo' => 1, 'X-FOO' => 2) }, bad(qr/'x-foo' given twice/),
      'same trailer twice, in different cases';
   is $mk->()->finish('X-Foo' => 1), "0\r\nx-amz-checksum-crc32:$expect{crc32}\r\nx-foo:1\r\n\r\n",
      'names are not case sensitive';

   # a bad value leaves the chunker as it was, signed or not
   my %bad_value = ("a\nb" => 'newline', "a\rb" => 'carriage return', "a\0b" => 'NUL',
      "\x{263a}" => 'wide character', 'ref' => 'reference');
   for my $signer ($x, $s3) {
      for my $value (sort keys %bad_value) {
         my $ck = $mk->($signer);
         is dies { $ck->finish('x-foo' => $value eq 'ref' ? {} : $value) },
            bad(qr/invalid value for trailer 'x-foo'/),
            ($signer == $x ? 'unsigned' : 'signed') . ": $bad_value{$value} in value";
         like $ck->finish('x-foo' => 'ok'), qr/\r\nx-foo:ok\r\n/, '... and the chunker can still finish';
      }
   }
   my $upgraded = "\xe9";
   utf8::upgrade($upgraded);
   my $body = $mk->()->finish('x-foo' => $upgraded);
   ok !utf8::is_utf8($body), 'a value stored as UTF-8 gives a byte string';
   is $body, "0\r\nx-amz-checksum-crc32:$expect{crc32}\r\nx-foo:\xe9\r\n\r\n", '... with the same bytes';
}

# --- configuration errors
ok dies { start($s3, streaming => 'unsigned') }, 'unsigned without trailers';
ok dies { start($s3, streaming => 1, checksum => 'md5') }, 'unknown checksum';
ok dies { start($s3, streaming => 1, checksum => 'crc32', trailers => ['x-amz-checksum-crc32']) }, 'same trailer twice';
ok dies { start($s3, streaming => 1, trailers => ['bad name']) }, 'invalid trailer name';
ok dies { start($s3, checksum => 'crc32') }, 'checksum without streaming';
ok dies { start($s3, trailers => ['x-foo']) }, 'trailers without streaming';
ok dies { start($s3, streaming => 'sideways') }, 'unknown streaming mode';
ok dies { start($x, streaming => 'signed', checksum => 'crc32') }, 'signed chunks need credentials';
ok lives { start($x, streaming => 'unsigned', checksum => 'crc32') }, 'unsigned works with x509';

# --- encoded_length equals the real length
my @cases = (
   [signed => 1, {}],
   [signed => 1, {checksum => 'crc32c'}, {streaming => 1, checksum => 'crc32c'}],
   [signed => 1, {trailers => {'x-amz-checksum-crc64nvme' => 12}}, {streaming => 1, trailers => ['x-amz-checksum-crc64nvme']}, {'x-amz-checksum-crc64nvme' => 'A' x 12}],
   [signed => 0, {checksum => 'sha256'}, {streaming => 'unsigned', checksum => 'sha256'}],
   [signed => 0, {checksum => 'sha1', trailers => {'x-foo' => 3}}, {streaming => 'unsigned', checksum => 'sha1', trailers => ['x-foo']}, {'x-foo' => 'abc'}],
);
for my $case (@cases) {
   my ($label, $signed, $opts, $sign, $values) = @$case;
   $sign //= {streaming => 1};
   for my $size (0, 1, 15, 16, 17, 255, 256, 300, 5000) {
      for my $chunk (16, 256, 1000) {
         my $c = start($signed ? $s3 : $x, %$sign, decoded_content_length => $size)->{chunker};
         my $data = 'z' x $size;
         my $body = '';
         for (my $off = 0; $off < $size; $off += $chunk) {
            $body .= $c->chunk(substr($data, $off, $chunk));
         }
         $body .= $c->finish(%{$values // {}});
         is length($body), AWS::Signature::V4->encoded_length($size, $chunk, signed => $signed, %$opts),
            "encoded_length: " . join(',', $signed ? 'signed' : 'unsigned', sort keys %$opts) . " size $size chunk $chunk";
      }
   }
}
is(AWS::Signature::V4->encoded_length(66560, 65536), 66824, 'still the AWS docs value without trailers');
ok dies { AWS::Signature::V4->encoded_length(10, 5, checksum => 'nope') }, 'encoded_length: unknown checksum';

done_testing;
