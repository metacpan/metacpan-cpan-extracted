use strict;
use warnings;
use Test::More;

use Crypt::Sodium::XS::Util qw(sodium_bin2ip sodium_ip2bin);
use Crypt::Sodium::XS::ipcrypt;

plan skip_all => 'no ipcrypt available'
  unless Crypt::Sodium::XS::ipcrypt::ipcrypt_available();

use FindBin '$Bin';
use lib "$Bin/lib";
use Test::MemVault;

my $ipcrypt = Crypt::Sodium::XS::->ipcrypt;

for my $var ($ipcrypt->primitives) {
  $ipcrypt->primitive($var);

  ok($ipcrypt->$_ > 0, "$_ > 0 ($var)") for qw(INPUTBYTES KEYBYTES OUTPUTBYTES);

  my $ip4_str = "10.9.8.7";
  my $ip6_str = "fe80::dead:beef:c0ff:eeee";

  my $key = $ipcrypt->keygen;
  ok($key, "key generated ($var)");
  is($key->size, $ipcrypt->KEYBYTES, "correct key length ($var)");

  my $ct = $ipcrypt->encrypt(sodium_ip2bin($ip4_str), $key);
  ok($ct, "ciphertext generated ($var)");
  is(length($ct), $ipcrypt->OUTPUTBYTES, "correct ciphertext length ($var)");

  my $pt = $ipcrypt->decrypt($ct, $key);
  ok($pt, "ciphertext decrypted ($var)");
  is(sodium_bin2ip($pt), $ip4_str, "ipv4 address roundtripped ($var)");

  $ct = $ipcrypt->encrypt(sodium_ip2bin($ip6_str), $key);
  $pt = $ipcrypt->decrypt($ct, $key);
  is(sodium_bin2ip($pt), $ip6_str, "ipv6 address roundtripped ($var)");

  if ($ipcrypt->TWEAKBYTES) {
    my $t1 = $ipcrypt->encrypt(sodium_ip2bin($ip4_str), $key);
    my $t2 = $ipcrypt->encrypt(sodium_ip2bin($ip4_str), $key);
    isnt(unpack("H*", $t1), unpack("H*", $t2), "$var is non-deterministic");
  }
}

done_testing();
