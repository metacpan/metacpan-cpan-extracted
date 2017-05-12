## no critic (RCS,VERSION,encapsulation,Module)

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok( 'Authen::Passphrase::SaltedSHA512',
        qw( generate_salted_sha512 validate_salted_sha512 ) )
      || print "Bail out!\n";
}

can_ok( 'Authen::Passphrase::SaltedSHA512',
    qw( generate_salted_sha512  validate_salted_sha512 ) );

my ( $salt_hex, $hash_hex ) = generate_salted_sha512('My Groovy Passphrase');

like( $salt_hex, qr/^[[:xdigit:]]{128}$/,
    'Salt generated contains 128 hex digits.' );

like( $hash_hex, qr/^[[:xdigit:]]{128}$/,
    'Hash generated contains 128 hex digits.' );

my $valid =
  validate_salted_sha512( 'My Groovy Passphrase', $salt_hex, $hash_hex );

ok( $valid, 'Correctly validated passphrase against good salt and hash.' );

my $in_valid = validate_salted_sha512( 'Bad passphrase', $salt_hex, $hash_hex );
ok( !$in_valid, 'Correctly rejected bad passphrase.' );

my $bad_salt_hex = $salt_hex;
$bad_salt_hex =~ s/.{32}/0123456789ABCDEF0123456789ABCDEF/smx; # Corrupted salt.

$in_valid =
  validate_salted_sha512( 'My Groovy Passphrase', $bad_salt_hex, $hash_hex );

ok( !$in_valid, 'Correctly rejected passphrase against bad salt good hash.' );

my $bad_hash_hex = $hash_hex;
$bad_hash_hex =~ s/.{32}/0123456789ABCDEF0123456789ABCDEF/smx; # Corrupted hash.
$in_valid =
  validate_salted_sha512( 'My Groovy Passphrase', $salt_hex, $bad_hash_hex );
ok( !$in_valid, 'Correctly rejected passphrase against good salt bad hash.' );

done_testing();
