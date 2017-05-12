#!perl -T
# make sure we can work with taint checking on
use Test::More;
eval "use Test::Taint";
plan skip_all => "Test::Taint required for this test" if $@;
plan tests => 4;

use Crypt::CAST5_PP;
my $cast5 = Crypt::CAST5_PP->new();
my $key = pack "H*", "0123456712345678234567893456789a";
taint($key);
eval { $cast5->init($key) };
ok(!$@, "init didn't blow up");

my $in = pack "H*", "0123456789abcdef";
taint($in);
my $enc = eval { $cast5->encrypt(pack "H*", "0123456789abcdef") };
ok(!$@, "encrypt didn't blow up");

taint($enc);
my $dec = eval { $cast5->decrypt($enc) };
ok(!$@, "decrypt didn't blow up");

is(unpack("H*",$in), unpack("H*",$dec), "input equals output");

