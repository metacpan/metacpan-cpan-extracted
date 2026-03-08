use strict;
use warnings;
use Test::More;
use Crypt::Liboqs::Sign qw(mldsa65_keypair mldsa65_sign mldsa65_verify);

my ($pk, $sk) = mldsa65_keypair();
ok(defined $pk && defined $sk, 'Generated key pair');

my $message = "Hello, post-quantum!";
my $signature = mldsa65_sign($message, $sk);
ok(defined $signature, 'Generated signature');

my $valid = mldsa65_verify($signature, $message, $pk);
ok($valid, 'Signature is valid');

my $invalid = mldsa65_verify($signature, "wrong message", $pk);
ok(!$invalid, 'Signature is invalid for wrong message');

done_testing();
