use Test::More;
use Crypt::PQClean::Sign qw(sphincs_shake256s_keypair sphincs_shake256s_sign sphincs_shake256s_verify);

my ($pk, $sk) = sphincs_shake256s_keypair();
ok(defined $pk && defined $sk, 'Generated key pair');

my $message = "Hello, post-quantum!";
my $signature = sphincs_shake256s_sign($message, $sk);
ok(defined $signature, 'Generated signature');

my $valid = sphincs_shake256s_verify($signature, $message, $pk);
ok($valid, 'Signature is valid');

my $message2 = "Hello, post-quantum?";
my $invalid = sphincs_shake256s_verify($signature, $message2, $pk);
ok(!$invalid, 'Signature is invalid');

done_testing();
