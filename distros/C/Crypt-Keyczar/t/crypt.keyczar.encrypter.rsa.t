use Test::More tests => 3;
use strict;
use warnings;
use FindBin;
use Crypt::Keyczar::Util;


sub BEGIN {
    use_ok('Crypt::Keyczar::Encrypter');
    use_ok('Crypt::Keyczar::Crypter');
}

my $KEYSET = "$FindBin::Bin/data/rsa";
my $CIPHER_TEXT = q{AJ4lzuqCPyrOTlknD2dcCOzClftq4L3g_u0UdyhJX6to7G9rayp4m9NAMO6u6A97XaTKRxLEUifLiqY0gSXSSSpTAUdUH4KMtM1aeF1uW6JO2iH7fO-kxP1boIwZlp3f9cza5_urG-0gvjjS-uGWBcc1Xz3rh5hzpGifBgTWGdttPS46TJGDQm9IAKhF8uDTBmWfaX_bmw6jc6ViDEY1nP2jU3rjAzQYd2f9kMp26nPZqpmHbGfKuFMI_yBEm-PEFAySR2ZwB190B6WI2NTSuoFg9_1CLbF1DLFWyXUwHrYY4wECK70zqq23sNn2XcUSwgYdvbISEkXotA8MBfETmTOt8Cti};

my $crypter = Crypt::Keyczar::Crypter->new($KEYSET);
ok($crypter->decrypt(Crypt::Keyczar::Util::decode($CIPHER_TEXT)) eq 'This is some test data', 'decrypt');
