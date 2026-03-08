use strict;
use warnings;
use Test::More;
use Crypt::Liboqs::Sign qw(falcon512_keypair falcon512_sign falcon512_verify);

my ($pk, $sk) = falcon512_keypair();
ok(defined $pk && defined $sk, 'Generated key pair');
is(length($pk), 897, 'Public key is 897 bytes');
is(length($sk), 1281, 'Secret key is 1281 bytes');

my $message = "Hello, post-quantum!";
my $signature = falcon512_sign($message, $sk);
ok(defined $signature, 'Generated signature');
ok(length($signature) > 0 && length($signature) <= 752, 'Signature length is valid');

my $valid = falcon512_verify($signature, $message, $pk);
ok($valid, 'Signature is valid');

my $message2 = "Hello, post-quantum?";
my $invalid = falcon512_verify($signature, $message2, $pk);
ok(!$invalid, 'Signature is invalid for wrong message');

# Test with a second keypair
my ($pk2, $sk2) = falcon512_keypair();
my $invalid2 = falcon512_verify($signature, $message, $pk2);
ok(!$invalid2, 'Signature is invalid for wrong public key');

done_testing();
