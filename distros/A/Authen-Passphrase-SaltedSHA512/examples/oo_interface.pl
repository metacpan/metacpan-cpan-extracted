#!/usr/bin/env perl

use strict;
use warnings;

use Authen::Passphrase::SaltedSHA512;

my $clear_passphrase = 'Stop Making Sense';

my $gen =
  Authen::Passphrase::SaltedSHA512->new( passphrase => $clear_passphrase );

my $salt_hex = $gen->salt_hex;
my $hash_hex = $gen->hash_hex;

# Now we'll assume that you've loaded $salt_hex and $hash_hex from a user
# database, and that the user is now trying to login by supplying a password
# that is held in $clear_passphrase:

my $auth = Authen::Passphrase::SaltedSHA512->new(
    salt_hex => $salt_hex,
    hash_hex => $hash_hex
);

if ( $auth->match($clear_passphrase) ) {
    print "That's a match.  Hmf! A lucky guess!\n";
}
else {
    print "Not even close!\n";
}
