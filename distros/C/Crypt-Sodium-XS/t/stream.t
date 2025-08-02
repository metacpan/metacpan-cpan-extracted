use strict;
use warnings;
use Test::More;

use Crypt::Sodium::XS::ProtMem ':constants';
use Crypt::Sodium::XS::OO::stream;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::MemVault;

my $msg = chr(0x42) x 160;

for my $alg (Crypt::Sodium::XS::OO::stream->primitives) {
  my $m = Crypt::Sodium::XS::OO::stream->new(primitive => $alg);

  ok($m->$_ > 0, "$_ > 0 ($alg)") for qw(KEYBYTES MESSAGEBYTES_MAX NONCEBYTES);

  my $key = $m->keygen;
  ok($key, "key generated ($alg)");
  is($key->length, $m->KEYBYTES, "key has correct length ($alg)");

  my $nonce;
  if ($alg =~ /^(?:chacha|salsa)20/) {
    eval { my $x = $m->nonce };
    like($@, qr/^Random nonces are unsafe with this primitive/,
         "random nonce disallowed ($alg)");
    $nonce = $m->nonce("\1");
  }
  else {
    $nonce = $m->nonce;
  }
  ok($nonce, "nonce generated ($alg)");
  is(length($nonce), $m->NONCEBYTES, "nonce has correct length ($alg)");

  my $bytes = $m->stream(32, $nonce, $key);
  ok($bytes, "stream output generated ($alg)");
  is(length($bytes), 32, "stream output has correct length ($alg)");

  my $ct = $m->xor($msg, $nonce, $key);
  ok($ct, "ciphertext generated ($alg)");
  is(length($ct), length($msg), "ciphertext has correct length ($alg)");

  my $pt = $m->xor($ct, $nonce, $key);
  ok($pt, "decrypted ciphertext ($alg)");
  is($pt, $msg, "decrypted ciphertext correctly ($alg)");

  $pt = $m->xor($ct, $nonce, $key, PROTMEM_ALL_DISABLED);
  isa_ok($pt, "Crypt::Sodium::XS::MemVault", "xor with flags returns MemVault ($alg)");
  is($pt->flags, PROTMEM_ALL_DISABLED, "xor with flags has correct flags ($alg)");
  is($pt->unlock, $msg, "xor with flags decrypted ciphertext correctly ($alg)");

  unless ($alg eq 'salsa2012') {
    my $ic = 0;
    my $ct_ic = $m->xor_ic($msg, $nonce, $ic, $key);
    ok($ct_ic, "ciphertext with ic generated ($alg)");
    is(length($ct_ic), length($msg), "ciphertext with ic has correct length ($alg)");
    is(unpack("H*", substr($ct_ic, 128)), unpack("H*", substr($ct, 128)),
         "xor_ic of 1 matches xor ($alg)");

    $pt = $m->xor_ic($ct_ic, $nonce, $ic, $key);
    ok($pt, "decrypted ciphertext with ic ($alg)");
    is($pt, $msg, "decrypted ciphertext with ic correctly ($alg)");

    $pt = $m->xor($ct, $nonce, $key, PROTMEM_ALL_DISABLED);
    isa_ok($pt, "Crypt::Sodium::XS::MemVault", "xor_ic with flags returns MemVault ($alg)");
    is($pt->flags, PROTMEM_ALL_DISABLED, "xor_ic with flags has correct flags ($alg)");
    is($pt->unlock, $msg, "xor_ic with flags decrypted ciphertext correctly ($alg)");
  }
}

done_testing();
