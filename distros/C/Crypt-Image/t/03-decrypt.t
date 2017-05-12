#!perl

use 5.006;
use strict; use warnings;
use Crypt::Image;
use Test::More tests => 3;

my $crypter = Crypt::Image->new(file => 't/key.png', type => 'png');
$crypter->encrypt('Hello World', 't/secret.png');

eval { $crypter->decrypt() };
like($@, qr/ERROR: Encrypted file missing/);

is($crypter->decrypt('t/secret.png'), 'Hello World');

eval { $crypter->decrypt('t/secret1.png') };
like($@, qr/ERROR: Encrypted file \[t\/secret1.png\] not found/);

unlink('t/secret.png');
