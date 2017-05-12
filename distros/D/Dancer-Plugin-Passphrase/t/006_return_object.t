use Test::More tests => 20;

use strict;
use warnings;

use Dancer qw(:tests);
use Dancer::Plugin::Passphrase;
use MIME::Base64 qw(decode_base64 encode_base64);

my $secret = "Super Secret Squirrel";

my $object = passphrase($secret)->generate;

ok(ref($object) eq 'Dancer::Plugin::Passphrase',  'Creates correct object');
ok($object->rfc2307,                              'Contains RFC 2307 representation');
ok($object->algorithm  eq 'Bcrypt',               'Contains correct scheme');
ok($object->cost       eq '04',                   'Contains correct cost');
ok($object->hash_raw,                             'Contains raw salt');
ok($object->hash_hex,                             'Contains hex hash');
ok($object->hash_base64,                          'Contains base64 hash');
ok($object->salt_raw,                             'Contains raw salt');
ok($object->salt_hex,                             'Contains hex salt');
ok($object->salt_base64,                          'Contains base64 salt');
ok($object->plaintext eq $secret,                 'Contains correct plaintext');


# Test that the salt / hash doesn't get changed when we create the RFC2307 string
my $salted_object = passphrase($secret)->generate({ algorithm => 'SHA-256', salt => 'A Bad Salt' });
my ($scheme, $settings) = ($salted_object->rfc2307 =~ m/^{(\w+)}(.*)/s);
my $extracted_salt = substr(decode_base64($settings), 256 / 8);
my $extracted_hash = substr(decode_base64($settings), 0, 256 / 8);


is(
    $extracted_salt,
    $salted_object->salt_raw,
    "Extracted raw salt is the same as the defined raw salt"
);

is(
    encode_base64($extracted_salt,''),
    $salted_object->salt_base64,
    "Extracted base64 salt is the same as the defined base64 salt"
);

is(
    unpack("H*", $extracted_salt),
    $salted_object->salt_hex,
    "Extracted hex salt is the same as the defined hex salt"
);

is(
    $extracted_hash,
    $salted_object->hash_raw,
    "Extracted raw hash is the same as the defined raw hash"
);

is(
    encode_base64($extracted_hash,''),
    $salted_object->hash_base64,
    "Extracted base64 hash is the same as the defined base64 hash"
);

is(
    unpack("H*", $extracted_hash),
    $salted_object->hash_hex,
    "Extracted hex hash is the same as the defined hex hash"
);



# Do check defined but empty salts too.
my $saltless_object = passphrase($secret)->generate({ algorithm => 'SHA-1', salt => '' });
ok(defined $saltless_object->salt_raw,    'Contains a defined, but empty raw salt');
ok(defined $saltless_object->salt_hex,    'Contains a defined, but empty hex salt');
ok(defined $saltless_object->salt_base64, 'Contains a defined, but empty base64 salt');


