use v5.24;
use experimental 'signatures';
use Test2::V0;
use FindBin '$Bin';
use lib "$Bin/../lib";
use AWS::Signature::V4;
use MIME::Base64 qw< encode_base64 >;
use File::Temp qw< tempdir >;

# chain items only need to be well-formed DER SEQUENCEs, tiny ones will do
my @der = map { "\x30\x03\x02\x01" . chr($_) } 1 .. 3;
my @b64 = map { encode_base64($_, '') } @der;
sub pem ($der) {
   "-----BEGIN CERTIFICATE-----\n" . encode_base64($der) . "-----END CERTIFICATE-----\n"
}
my @pem = map { pem($_) } @der;

my $dir = tempdir(CLEANUP => 1);
sub file ($name, $content) {
   open my $fh, '>:raw', "$dir/$name" or die;
   print {$fh} $content;
   close $fh;
   return "$dir/$name";
}

sub chain_header (%x) {
   my $s = AWS::Signature::V4->new(service => 'rolesanywhere', region => 'r', x509 => {
      key_type  => 'ECDSA', certificate => $pem[0], serial => 1,
      signer => sub { 'sig' }, %x});
   my $r = $s->sign(method => 'GET', url => 'https://h/', time => 0);
   return $r->{headers}{'x-amz-x509-chain'};
}

my $both = join ',', @b64[1, 2];
is chain_header(), undef, 'no chain, no header';
is chain_header(chain => [$pem[1], $pem[2]]), $both, 'chain, PEM contents';
is chain_header(chain => [$der[1], $der[2]]), $both, 'chain, DER contents';
is chain_header(chain => [$pem[1], $der[2]]), $both, 'chain, mixed';
is chain_header(chain => [$pem[1] . $pem[2]]), $both, 'chain, PEM bundle';

is chain_header(chain => $pem[1] . $pem[2]), $both, 'chain, plain PEM string';
is chain_header(chain => $pem[1]), $b64[1], 'chain, plain PEM string with one certificate';
ok dies { chain_header(chain => $der[1]) }, 'chain, plain string must be PEM';
ok dies { chain_header(chain => 'garbage') }, 'chain, plain string garbage rejected';

my $sep = "\n\n   \n\t\n \r\n\n";
is chain_header(chain => $pem[1] . $sep . $pem[2]), $both,
   'chain, sections separated by empty and whitespace-only lines';
is chain_header(chain => $sep . $pem[1] . $sep . $pem[2] . $sep), $both,
   'chain, leading and trailing blank lines';
(my $crlf = $pem[1] . "\n" . $pem[2]) =~ s/\n/\r\n/g;
is chain_header(chain => $crlf), $both, 'chain, CRLF line endings';
is chain_header(chain_files => file(spaced => $pem[1] . $sep . $pem[2])), $both,
   'chain_files, blank-line separated bundle';

my @f = (file(a => $pem[1]), file(b => $der[2]));
is chain_header(chain_files => \@f), $both, 'chain_files, PEM and DER files';
is chain_header(chain_files => file(single => $pem[1] . $pem[2])), $both,
   'chain_files, plain string path';
is chain_header(chain_files => $f[1]), $b64[2], 'chain_files, plain path to a DER file';
is chain_header(chain_files => [file(bundle => $pem[1] . $pem[2])]), $both,
   'chain_files, PEM bundle';
is chain_header(chain => [$pem[2]], chain_files => \@f), $b64[2],
   'chain wins over chain_files';
ok dies { chain_header(chain_files => ["$dir/missing"]) }, 'missing file croaks';
ok dies { chain_header(chain => ["-----BEGIN X-----\nAA==\n-----END X-----\n"]) },
   'PEM without certificates croaks';

my $r = AWS::Signature::V4->new(service => 's', region => 'r', x509 => {
      key_type  => 'RSA', certificate => $pem[0], serial => 1,
      chain => [$pem[1]], signer => sub { 'sig' }})
   ->sign(method => 'GET', url => 'https://h/', time => 0);
like $r->{signed_headers}, qr/x-amz-x509-chain/, 'chain header is signed';

done_testing;
