#!perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Crypt::PBKDF2;

my $pbkdf2 = Crypt::PBKDF2->new(
  length_limit => 8
);

my $hash;

is exception { $hash = $pbkdf2->generate("12345678") }, undef, "doesn't die on generate with valid length";
is exception {
  is $pbkdf2->validate($hash, "12345678"), 1, "hash validates"
}, undef, "doesn't die on validate with valid length";

like exception { $hash = $pbkdf2->generate("123456789") }, qr/length limit/, "dies on generate with too long pw";
like exception {
  is $pbkdf2->validate($hash, "123456789"), 1, "hash validates"
}, qr/length limit/, "dies on validate with too long pw";

done_testing;
