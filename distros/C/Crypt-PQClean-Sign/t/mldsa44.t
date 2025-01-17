use Test::More;
use Crypt::PQClean::Sign qw(mldsa44_keypair mldsa44_sign mldsa44_verify);

my ($pk, $sk) = mldsa44_keypair();
ok(defined $pk && defined $sk, 'Generated key pair');

my $message = "Hello, post-quantum!";
my $signature = mldsa44_sign($message, $sk);
ok(defined $signature, 'Generated signature');

my $valid = mldsa44_verify($signature, $message, $pk);
ok($valid, 'Signature is valid');

my $message2 = "Hello, post-quantum?";
my $invalid = mldsa44_verify($signature, $message2, $pk);
ok(!$invalid, 'Signature is invalid');

done_testing();
