#!perl
use strict;
use warnings;
use Test::More;

# Tests from draft-raeburn-krb-rijndael-krb-04.txt

BEGIN {
  use_ok 'Crypt::PBKDF2';
}

my $pbkdf2 = Crypt::PBKDF2->new(hash_class => 'HMACSHA1');

sub PBKDF2 {
  my ($iterations, $bits, $salt, $password) = @_;

  return $pbkdf2->clone(iterations => $iterations, output_len => $bits / 8)->PBKDF2_hex($salt, $password);

}

is PBKDF2(1, 128, "ATHENA.MIT.EDUraeburn", "password"),
  "cdedb5281bb2f801565a1122b2563515", "raeburn 1 iter, 128-bit";

is PBKDF2(1, 256, "ATHENA.MIT.EDUraeburn", "password"),
  "cdedb5281bb2f801565a1122b25635150ad1f7a04bb9f3a333ecc0e2e1f70837", "raeburn 1 iter, 256-bit";

is PBKDF2(2, 128, "ATHENA.MIT.EDUraeburn", "password"),
  "01dbee7f4a9e243e988b62c73cda935d", "raeburn 2 iter, 128-bit";

is PBKDF2(2, 256, "ATHENA.MIT.EDUraeburn", "password"),
  "01dbee7f4a9e243e988b62c73cda935da05378b93244ec8f48a99e61ad799d86", "raeburn 2 iter, 256-bit";
 
is PBKDF2(1200, 128, "ATHENA.MIT.EDUraeburn", "password"),
  "5c08eb61fdf71e4e4ec3cf6ba1f5512b", "raeburn 1200 iter, 128-bit";

is PBKDF2(1200, 256, "ATHENA.MIT.EDUraeburn", "password"),
  "5c08eb61fdf71e4e4ec3cf6ba1f5512ba7e52ddbc5e5142f708a31e2e62b1e13", "raeburn 1200 iter, 256-bit";

is PBKDF2(1200, 256, "pass phrase equals block size", "X" x 64),
  "139c30c0966bc32ba55fdbf212530ac9c5ec59f1a452f5cc9ad940fea0598ed1", "raeburn pass phrase equals block size, 256-bit";

is PBKDF2(1200, 256, "pass phrase exceeds block size", "X" x 65),
  "9ccad6d468770cd51b10e6a68721be611a8b4d282601db3b36be9246915ec82a", "raeburn pass phrase exceeds block size, 256-bit";

use Encode ();
is PBKDF2(50, 256, "EXAMPLE.COMpianist", Encode::encode("UTF-8", "\x{1d11e}") ),
  "6b9cf26d45455a43a5b8bb276a403b39e7fe37a0c41e02c281ff3069e1e94f52", "raeburn pianist, 256-bit";

done_testing;
