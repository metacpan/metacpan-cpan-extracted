# See if we can interoperate with Crypt::CBC
use Test::More;

# prior to 1.22, Crypt::CBC didn't use the Crypt:: prefix to locate ciphers
eval "use Crypt::CBC 1.22";
plan skip_all => "Crypt::CBC required for this test" if $@;
plan tests => 2;

my $cbc = Crypt::CBC->new("0123456789abcdef", "CAST5_PP");

my $msg = "'Twas brillig, and the slithy toves";
my $c = $cbc->encrypt($msg);
is(length($c), 56, "ciphertext length check");
my $d = $cbc->decrypt($c);
is(unpack("H*",$d), unpack("H*",$msg), "encrypt-decrypt");

# end 2cbc.t
