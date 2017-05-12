# Check operations on utf8 data
use Test::More;
use Crypt::CAST5;

if ($] < 5.006) {
  plan skip_all => "utf8 not supported by this perl version";
}
else {
  plan tests => 8;
}

my $cast5 = Crypt::CAST5->new();

my $key = utf8_upgrade(pack "H*", "0123456712345678234567893456789a");
my $init = eval { $cast5->init($key); 1 };
ok($init, "initialize with utf8 key");

my $plain = utf8_upgrade(pack "H*", "0123456789abcdef");
my $enc = eval { unpack "H*", $cast5->encrypt($plain) };
is($enc, "238b4fe5847e44b2", "encrypt utf8 data");

my $cipher = utf8_upgrade(pack "H*", "238b4fe5847e44b2");
my $dec = eval { unpack "H*", $cast5->decrypt($cipher) };
is($dec, "0123456789abcdef", "decrypt utf8 data");

my $bad = "123456" . chr(300);
$dec = eval { $cast5->decrypt($bad) };
is($dec, undef, "decrypt 8-byte bad data");
$enc = eval { $cast5->encrypt($bad) };
is($enc, undef, "encrypt 8-byte bad data");

$bad = "1234567" . chr(300);
$dec = eval { $cast5->decrypt($bad) };
is($dec, undef, "decrypt 8-char bad data");
$enc = eval { $cast5->encrypt($bad) };
is($enc, undef, "encrypt 8-char bad data");
$init = eval { $cast5->init($bad); 1 };
is($init, undef, "bad key");

sub utf8_upgrade {
  my ($str) = @_;
  $str = chr(300) . $str;
  return substr($str, 1);
} # utf8_upgrade

# end 3utf8.t
