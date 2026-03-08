use strict;
use warnings;
use Test::More;
use Crypt::Liboqs::Sign qw(mldsa87_keypair mldsa87_sign mldsa87_verify);

my ($pk, $sk) = mldsa87_keypair();
ok(defined $pk && defined $sk, 'Generated key pair');

my $message = "Hello, post-quantum!";
my $signature = mldsa87_sign($message, $sk);
ok(defined $signature, 'Generated signature');

my $valid = mldsa87_verify($signature, $message, $pk);
ok($valid, 'Signature is valid');

my $invalid = mldsa87_verify($signature, "wrong message", $pk);
ok(!$invalid, 'Signature is invalid for wrong message');

done_testing();
