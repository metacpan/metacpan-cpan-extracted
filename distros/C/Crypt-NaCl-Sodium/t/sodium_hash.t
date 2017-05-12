
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw(:utils);

my $crypto_hash = Crypt::NaCl::Sodium->hash();

my (@k, @in);

ok($crypto_hash->$_ > 0, "$_ > 0") for qw( SHA256_BYTES SHA512_BYTES );

my $x = "testing\n";
my $x2 = "The Conscience of a Hacker is a small essay written January 8, 1986 by a computer security hacker who went by the handle of The Mentor, who belonged to the 2nd generation of Legion of Doom.";

my $xhash512 = $crypto_hash->sha512( $x );
my $x2hash512 = $crypto_hash->sha512( $x2 );

is(bin2hex($xhash512),
    "24f950aac7b9ea9b3cb728228a0c82b67c39e96b4b344798870d5daee93e3ae5931baae8c7cacfea4b629452c38026a81d138bc7aad1af3ef7bfd5ec646d6c28",
    "sha512 for x as expected");

is(bin2hex($x2hash512),
    "a77abe1ccf8f5497e228fbc0acd73a521ededb21b89726684a6ebbc3baa32361aca5a244daa84f24bf19c68baf78e6907625a659b15479eb7bd426fc62aafa73",
    "sha512 for x2 as expected");

my $xhash256 = $crypto_hash->sha256( $x );
my $x2hash256 = $crypto_hash->sha256( $x2 );

is(bin2hex($xhash256),
    "12a61f4e173fb3a11c05d6471f74728f76231b4a5fcd9667cef3af87a3ae4dc2",
    "sha256 for x as expected");

is(bin2hex($x2hash256),
    "71cc8123fef8c236e451d3c3ddf1adae9aa6cd9521e7041769d737024900a03a",
    "sha256 for x2 as expected");

done_testing();

