## no critic (RCS,VERSION,encapsulation,Module)

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('Authen::Passphrase::SaltedSHA512') || print "Bail out!\n";
}

my $gen = new_ok(
    'Authen::Passphrase::SaltedSHA512',
    [ passphrase => 'There can only be one' ],
    'Passphrase hash generation object'
);

my $good_salt_hex = $gen->salt_hex;
like( $good_salt_hex, qr/^[[:xdigit:]]{128}$/, 'Generated a valid salt.' );

my $good_hash_hex = $gen->hash_hex;
like( $good_hash_hex, qr/^[[:xdigit:]]{128}$/, 'Generated a valid hash.' );

my $auth = new_ok(
    'Authen::Passphrase::SaltedSHA512',
    [
        salt_hex => $good_salt_hex,
        hash_hex => $good_hash_hex
    ],
    'Passphrase challenge object'
);

my $valid    = $auth->match('There can only be one');
my $in_valid = $auth->match('Bad guy');

ok( $valid,     'Authenticated good passphrase.' );
ok( !$in_valid, 'Rejected bad passphrase.' );

done_testing();
