use strict;
use warnings;
use Test::More;
use Crypt::Liboqs::Sign qw(falcon1024_keypair falcon1024_sign falcon1024_verify);

my ($pk, $sk) = falcon1024_keypair();
ok(defined $pk && defined $sk, 'Generated key pair');
is(length($pk), 1793, 'Public key is 1793 bytes');
is(length($sk), 2305, 'Secret key is 2305 bytes');

my $message = "Hello, post-quantum!";
my $signature = falcon1024_sign($message, $sk);
ok(defined $signature, 'Generated signature');

my $valid = falcon1024_verify($signature, $message, $pk);
ok($valid, 'Signature is valid');

my $invalid = falcon1024_verify($signature, "wrong message", $pk);
ok(!$invalid, 'Signature is invalid for wrong message');

done_testing();
