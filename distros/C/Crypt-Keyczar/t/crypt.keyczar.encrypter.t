use Test::More tests => 7;
use strict;
use warnings;
use FindBin;
use Crypt::Keyczar qw(KEY_HASH_SIZE FORMAT_VERSION);
use Crypt::Keyczar::Util;


sub BEGIN {
    use_ok('Crypt::Keyczar::Encrypter');
    use_ok('Crypt::Keyczar::Crypter');
}
my $KEYSET = "$FindBin::Bin/data/encrypter";
my $MESSAGE = "This is some test data";

my $encrypter = Crypt::Keyczar::Encrypter->new($KEYSET);
ok($encrypter, 'create encrypter');
my $cipher = $encrypter->encrypt($MESSAGE);
ok($cipher, 'encrypt');
my $crypter = Crypt::Keyczar::Crypter->new($KEYSET);
ok($crypter->decrypt($cipher) eq $MESSAGE);

$crypter = Crypt::Keyczar::Crypter->new($KEYSET);
my $primary = Crypt::Keyczar::Util::decode('AFc0B7_bAchrUqkm91ivaKjSMoJ0qOkNEi0mlAw5yH1JNx2FNTOS3ZrsCXGIqRupKGx1t3GlEweW44YlKgbguhwOHGYsFW0cgw');
my $secondary = Crypt::Keyczar::Util::decode('AMvKR8624iadM163FEtP28tUzzB0F4768NOXyYgt7oNjIf4dCzPstnVwo__x0hUmyEtFYslf8mFYRor3NvqGZG-Sw7IjHN64Eg');
ok($crypter->decrypt($primary) eq $MESSAGE, 'primary key decrypt');
ok($crypter->decrypt($secondary) eq $MESSAGE, 'secondary key decrypt');
