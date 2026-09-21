use v5.24;
use experimental 'signatures';
use Test2::V0;
use FindBin '$Bin';
use lib "$Bin/../lib";
use AWS::Signature::V4;
use Digest::SHA qw< sha256_hex >;
use File::Temp qw< tempfile >;

my $s3 = AWS::Signature::V4->new(
   service => 's3', region => 'us-east-1',
   credentials => {
      access_key_id     => 'AKIAIOSFODNN7EXAMPLE',
      secret_access_key => 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
   },
);

# Example from the AWS docs: PUT with signed chunks (64 KiB, 1 KiB, final)
is(AWS::Signature::V4->encoded_length(66560, 65536), 66824, 'encoded length, as in the docs');

my $r = $s3->sign(
   method    => 'PUT',
   url       => 'https://s3.amazonaws.com/examplebucket/chunkObject.txt',
   headers   => {
      'x-amz-storage-class' => 'REDUCED_REDUNDANCY',
      'Content-Encoding'    => 'aws-chunked',
      'Content-Length'      => 66824,
   },
   streaming              => 1,
   decoded_content_length => 66560,
   time                   => 1369353600,
);
like $r->{authorization}, qr/Signature=4f232c4386841ef735655705268965c44a0e4690baa4adea153f7db9fa80a0a9$/,
   'seed signature matches AWS docs';
is $r->{signed_headers},
   'content-encoding;content-length;host;x-amz-content-sha256;x-amz-date;x-amz-decoded-content-length;x-amz-storage-class',
   'signed headers';
is $r->{headers}{'x-amz-content-sha256'}, 'STREAMING-AWS4-HMAC-SHA256-PAYLOAD', 'payload marker';
is $r->{headers}{'x-amz-decoded-content-length'}, 66560, 'decoded length header';

my $ck = $r->{chunker};
my $first = 'a' x 65536;
my $c1 = $ck->chunk(\$first);
like $c1, qr/\A10000;chunk-signature=ad80c730a21e5b8d04586a2213dd63b9a0e99e0e2307b0ade35a65485a288648\r\n/,
   'first chunk signature matches';
my $c2 = $ck->chunk('a' x 1024);
like $c2, qr/\A400;chunk-signature=0055627c9e194cb4542bae2aa5492e3c1575bbb81b612b7d234b86a503ef5497\r\n/,
   'second chunk signature matches';
my $c3 = $ck->finish;
is $c3, "0;chunk-signature=b6c6ea8a5354eaf15b3cb7646744f4275b71ea724fed81ceb9323e279d449df9\r\n\r\n",
   'final chunk matches';
is length($c1 . $c2 . $c3), 66824, 'body is as long as announced';
is substr($c1, -2), "\r\n", 'chunk ends with CRLF';
ok dies { $ck->finish }, 'cannot finish twice';
ok dies { $ck->chunk('x') }, 'nor add chunks afterwards';

# defaults and validation
$r = $s3->sign(method => 'PUT', url => 'https://h/k', streaming => 1,
   decoded_content_length => 0, time => 0);
is $r->{headers}{'content-encoding'}, 'aws-chunked', 'Content-Encoding added';
$r = $s3->sign(method => 'PUT', url => 'https://h/k', streaming => 1,
   decoded_content_length => 0, headers => {'Content-Encoding' => 'gzip'}, time => 0);
is $r->{headers}{'content-encoding'}, 'gzip,aws-chunked', 'aws-chunked goes after an existing Content-Encoding';
$r = $s3->sign(method => 'PUT', url => 'https://h/k', streaming => 1,
   decoded_content_length => 0, headers => {'Content-Encoding' => 'AWS-Chunked, gzip'}, time => 0);
is $r->{headers}{'content-encoding'}, 'gzip,aws-chunked', 'and it is not repeated';
like $r->{signed_headers}, qr/\bcontent-encoding\b/, 'Content-Encoding is signed';
$r = $s3->sign(method => 'PUT', url => 'https://h/k', streaming => 1,
   decoded_content_length => 0, signed_headers => [], time => 0);
is $r->{signed_headers}, 'content-encoding;host;x-amz-content-sha256;x-amz-date;x-amz-decoded-content-length',
   'even with an explicit list, the headers of streaming are signed';
ok dies { $s3->sign(method => 'PUT', url => 'https://h/k', streaming => 1) },
   'decoded_content_length is required';
ok dies { $s3->sign(method => 'PUT', url => 'https://h/k', streaming => 1,
   decoded_content_length => 'x') }, 'and must be a number';
ok dies { $s3->presign(url => 'https://h/k', streaming => 1, decoded_content_length => 1) },
   'no streaming with presign';

my $x = AWS::Signature::V4->new(service => 's3', region => 'r', x509 => {
      key_type  => 'RSA', serial => 1, signer => sub { 'x' },
      certificate => "-----BEGIN CERTIFICATE-----\nMAMCAQc=\n-----END CERTIFICATE-----\n"});
ok dies { $x->sign(method => 'PUT', url => 'https://h/k', streaming => 1,
   decoded_content_length => 0) }, 'no streaming with x509';

my $short = $s3->sign(method => 'PUT', url => 'https://h/k', streaming => 1,
   decoded_content_length => 4, time => 0)->{chunker};
$short->chunk('ab');
ok dies { $short->finish }, 'finish() checks the total length';
ok dies { $short->chunk('abc') }, 'chunk() checks the total length';
ok dies { $short->chunk('') }, 'empty chunks are refused';
is dies { $short->chunk("\x{263a}") }, bad(qr/chunk must be a byte string/), 'wide characters are refused';

is(AWS::Signature::V4->encoded_length(0, 10), 86, 'empty body: only the final chunk');
is(AWS::Signature::V4->encoded_length(20, 10), 2 * (1 + 17 + 64 + 2 + 10 + 2) + 86 - 0,
   'two full chunks');
is(AWS::Signature::V4->encoded_length(25, 10), 2 * (1 + 17 + 64 + 2 + 10 + 2) + (1 + 17 + 64 + 2 + 5 + 2) + 86,
   'partial last chunk');

# body_fh: the hash of the file, without loading it
my ($fh, $file) = tempfile(UNLINK => 1);
binmode $fh;
my $data = join '', map { chr($_ % 256) } 1 .. 300_000;
print {$fh} $data;
close $fh;
open my $in, '<:raw', $file or die;
seek $in, 5, 0;
my $std = AWS::Signature::V4->new(service => 'service', region => 'r',
   credentials => {access_key_id => 'A', secret_access_key => 'S'});
my $viafh  = $std->sign(method => 'PUT', url => 'https://h/', body_fh => $in, time => 0);
my $viabody = $std->sign(method => 'PUT', url => 'https://h/', body => substr($data, 5), time => 0);
is $viafh->{signature}, $viabody->{signature}, 'body_fh hashes from the current position to the end';
is tell($in), 5, 'and the file position is restored';
ok dies { $std->sign(method => 'PUT', url => 'https://h/', body_fh => $in, body => 'x') },
   'body and body_fh together are refused';
my $pfh = $std->presign(url => 'https://h/', body_fh => $in, time => 0);
my $pbody = $std->presign(url => 'https://h/', body => substr($data, 5), time => 0);
is $pfh->{signature}, $pbody->{signature}, 'body_fh works with presign too';

sub bad ($re) {
   object { prop blessed => 'Ouch'; call code => 400; call message => match $re };
}

# body_fh must be put back where it was, so it must be seekable and binary
open my $pipe, '-|', $^X, '-e', 'print "hello"' or die "pipe: $!";
is dies { $std->sign(method => 'PUT', url => 'https://h/', body_fh => $pipe) },
   bad(qr/seekable/), 'a pipe is refused';
is do { local $/; <$pipe> }, 'hello', 'and it is not consumed';
close $pipe;
open my $text, '<:encoding(UTF-8)', $file or die;
is dies { $std->sign(method => 'PUT', url => 'https://h/', body_fh => $text) },
   bad(qr/binary/), 'a handle with an encoding layer is refused';
open my $wo, '>>', $file or die;
is dies { $std->sign(method => 'PUT', url => 'https://h/', body_fh => $wo) },
   bad(qr/cannot be read/), 'a write-only handle is refused';
close $wo;

# encoded_length checks what it gets
my %bad_length = (
   'signed as a word'   => [[10, 4, checksum => 'crc32', signed => 'yes'], qr/signed/],
   'negative size'      => [[-5, 10], qr/decoded size/],
   'fractional size'    => [[10.5, 4], qr/decoded size/],
   'size not a number'  => [['abc', 10], qr/decoded size/],
   'chunk size 8k'      => [[10, '8k'], qr/chunk size/],
   'chunk size zero'    => [[10, 0], qr/chunk size/],
   'odd options'        => [[10, 4, 'signed'], qr/pairs/],
   'trailers as list'   => [[10, 8192, trailers => ['x']], qr/hash reference/],
   'trailer length'     => [[10, 8192, trailers => {'x-foo' => -1}], qr/length/],
   'trailer name'       => [[10, 8192, trailers => {'x foo' => 1}], qr/trailer name/],
   'unknown option'     => [[10, 8192, sgned => 0], qr/unsupported for encoded_length: "sgned"/],
   # sign() refuses these too: the two must not disagree on what is valid
   'trailer twice'      => [[10, 8192, checksum => 'crc32',
                             trailers => {'x-amz-checksum-crc32' => 8}], qr/declared twice/],
   'same name twice'    => [[10, 8192, trailers => {'x-foo' => 1, 'X-Foo' => 1}], qr/declared twice/],
);
for my $name (sort keys %bad_length) {
   my ($args, $re) = $bad_length{$name}->@*;
   is dies { AWS::Signature::V4->encoded_length(@$args) }, bad($re), "encoded_length: $name";
}

# one argument dies because of the signature, not the inner validation
like dies { AWS::Signature::V4->encoded_length(10) }, qr{(?mxs: Too\ few\ arguments)},
   'encoded_length: one argument';

is(AWS::Signature::V4->encoded_length(10, 4, checksum => 'crc32', signed => 'unsigned'),
   AWS::Signature::V4->encoded_length(10, 4, checksum => 'crc32', signed => 0),
   'encoded_length: signed => "unsigned" is like sign(streaming => "unsigned")');
is(AWS::Signature::V4->encoded_length(10, 4, signed => 'signed'),
   AWS::Signature::V4->encoded_length(10, 4), 'encoded_length: signed => "signed"');

done_testing;
