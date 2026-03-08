use strict;
use warnings;
use Test::More;
use Crypt::Liboqs::Sign qw(mldsa44_keypair mldsa44_sign mldsa44_verify);

my ($pk, $sk) = mldsa44_keypair();
ok(defined $pk && defined $sk, 'Generated key pair');

my $message = "Hello, post-quantum!";
my $signature = mldsa44_sign($message, $sk);
ok(defined $signature, 'Generated signature');

my $valid = mldsa44_verify($signature, $message, $pk);
ok($valid, 'Signature is valid');

my $invalid = mldsa44_verify($signature, "wrong message", $pk);
ok(!$invalid, 'Signature is invalid for wrong message');

done_testing();
