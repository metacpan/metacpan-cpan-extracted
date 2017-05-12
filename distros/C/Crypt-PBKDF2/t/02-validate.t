#!perl
use strict;
use warnings;

use Test::More;

use constant TEST_PASSWORDS => 500;

BEGIN {
  plan tests => 8 * TEST_PASSWORDS + 1; # + use_ok
  use_ok 'Crypt::PBKDF2';
}

for my $encoding (qw(ldap crypt)) {
  my $pbkdf2 = Crypt::PBKDF2->new(iterations => 40, encoding => $encoding);

  for my $i (1 .. TEST_PASSWORDS) {
    my $password = join "", map ["A".."Z","a".."z","0".."9"]->[rand 62], 1..8;
    my $hash = $pbkdf2->generate($password);
    ok $pbkdf2->validate($hash, $password), "Validate password $i: $password ($encoding)";

    is length $pbkdf2->PBKDF2('test', $password), 20, "raw length $password";
    is length $pbkdf2->PBKDF2_hex('test', $password), 40, "hex length $password";
    is length $pbkdf2->PBKDF2_base64('test', $password), 28, "base64 length $password";
  }
}
