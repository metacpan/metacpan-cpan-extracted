
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw( :utils );

my $crypto_pwhash = Crypt::NaCl::Sodium->pwhash();

my ($salt, $key, $hashed, $password);

# Some simple password vulnerable to dictionary attack
$password = "letmein1";

## Key derivation
########

# generate salt
$salt = '1' x $crypto_pwhash->SALTBYTES;
ok($salt, "salt generated");

# can be used later in other methods as the actual key
$key = $crypto_pwhash->key( $password, $salt, bytes => 32 );
is($key->to_hex,
    "d20c5e1859e4feda4d7f970912c7ca84401338f068d44c445fedb3a60fc3e6b9", "key derived");

## Password storage
########

# save this in database as hash of user password
$hashed = $crypto_pwhash->str( $password );
is(length($hashed), $crypto_pwhash->STRBYTES, "password hash has correct length");
like($hashed, qr/\0$/, "...with null byte at the end");

done_testing();

