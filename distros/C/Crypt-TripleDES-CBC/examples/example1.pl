use 5.010;
use Crypt::TripleDES::CBC;

my $key = pack("H*"
    , "1234567890123456"
    . "7890123456789012");
my $iv = pack("H*","0000000000000000");
my $crypt = Crypt::TripleDES::CBC->new(
    key => $key,
    iv  => $iv,
);

say unpack("H*",$crypt->encrypt(pack("H*","0ABC0F2241535345631FCE")));
say unpack("H*",$crypt->decrypt(pack("H*","F64F2268BF6185A16DADEFD7378E5CE5")));

