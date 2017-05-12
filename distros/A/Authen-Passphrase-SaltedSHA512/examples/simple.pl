#!/usr/bin/perl

use strict;
use warnings;
use Authen::Passphrase::SaltedSHA512
  qw( generate_salted_sha512 validate_salted_sha512 );

my $clear_password = 'Planet Claire';

my ( $salt_hex, $hash_hex ) = generate_salted_sha512($clear_password);

print "Your random salt is: $salt_hex\n";
print "Your salted and hashed passphrase is: $hash_hex\n";

# Now let's assume that we loaded $salt_hex and $hash_hex from a user database.
# And we'll assume that a user is attempting to log in, having supplied a
# password that is held in $clear_password:

if ( validate_salted_sha512( $clear_password, $salt_hex, $hash_hex ) ) {
    print "Bingo!  That's the correct password.\n";
}
else {
    print "That's not even close!\n";
}

