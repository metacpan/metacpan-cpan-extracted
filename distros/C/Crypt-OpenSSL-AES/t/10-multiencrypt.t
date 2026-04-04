use strict;
use warnings;
use Test::More tests => 6;
use Crypt::OpenSSL::AES;

my $key = pack("H*", "0" x 64);   # 32-byte key
my $c = Crypt::OpenSSL::AES->new($key, { cipher => 'AES-256-ECB' });

my $first  = $c->encrypt("Hello World. 123");
my $second = $c->encrypt("Hello World. 123");
ok($first eq $second,     "ECB: same plaintext gives same ciphertext on second call");
ok($c->decrypt($first) eq "Hello World. 123",  "ECB: first decrypt correct");
ok($c->decrypt($second) eq "Hello World. 123", "ECB: second decrypt correct");

my $c2 = Crypt::OpenSSL::AES->new($key, {
    cipher => 'AES-256-CBC', iv => pack("H*", "0" x 32), padding => 1
});
my $ct1 = $c2->encrypt("Hello World. 123");
my $ct2 = $c2->encrypt("Hello World. 123");
ok($ct1 eq $ct2, "CBC: same key+iv gives identical ciphertext on repeated calls");
ok($c2->decrypt($ct1) eq "Hello World. 123", "CBC: ciphertext decrypts correctly");
ok($c2->decrypt($ct2) eq "Hello World. 123", "CBC: ciphertext decrypts correctly");

