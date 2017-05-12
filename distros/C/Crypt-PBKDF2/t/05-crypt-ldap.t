#!perl
use strict;
use warnings;

use Test::More;

BEGIN {
  plan tests => 1 + 1;
  use_ok 'Crypt::PBKDF2';
}

my $encoder = Crypt::PBKDF2->new(
  hash_class => 'HMACSHA2',
  hash_args  => { sha_size => 512 },
  iterations => 100,
  salt_len   => 32,
  encoding   => 'crypt',
);

my $password = "testpass";

my $hash = $encoder->generate($password);

my $decoder = Crypt::PBKDF2->new; # Defaults to LDAP encoding, different hash, etc.

ok $decoder->validate($hash, $password), "Old crypt hash validates with new PBKDF2 that wants LDAP";
