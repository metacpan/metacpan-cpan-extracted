use warnings;
use strict;

use Test::More tests => 3;

BEGIN { use_ok "Crypt::Eksblowfish::Bcrypt", qw(bcrypt_hash); }

is bcrypt_hash({ key_nul => 0, cost => 5, salt => "abcdefghijklmnop" },
	       "supercalifragilisticexpialidocious"),
   pack("H*", "1e514c325869b8c311f852ffe630bac51519a66409ed77");

is bcrypt_hash({ key_nul => 1, cost => 6, salt => "ABCDEFGHIJKLMNOP" },
	       "Libelar! Timmah!"),
   pack("H*", "2b7453cbc43bc27cb59c1a1a2ce520d79557f7a1a17b9b");

1;
