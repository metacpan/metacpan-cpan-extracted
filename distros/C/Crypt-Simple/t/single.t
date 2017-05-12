#!/usr/bin/perl -w
use strict;
use Test;

plan tests => 5;

use Crypt::Simple;

my $plaintext = "A message before encryption or after decryption";
my $ciphertext = encrypt($plaintext);
my $nonsense = "Hello World!";

ok($ciphertext);
ok($ciphertext ne encrypt($nonsense));
ok($ciphertext eq encrypt($plaintext));
ok($plaintext eq decrypt($ciphertext));
eval { decrypt('VGhpcyBpcyBhIHRlc3Q=') };
ok($@);
