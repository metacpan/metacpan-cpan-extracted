use Test::More;
use Crypt::PQClean::Sign qw(sphincs_shake128f_keypair sphincs_shake128f_sign sphincs_shake128f_verify);

my ($pk, $sk) = sphincs_shake128f_keypair();
ok(defined $pk && defined $sk, 'Generated key pair');

my $message = "Hello, post-quantum!";
my $signature = sphincs_shake128f_sign($message, $sk);
ok(defined $signature, 'Generated signature');

my $valid = sphincs_shake128f_verify($signature, $message, $pk);
ok($valid, 'Signature is valid');

my $message2 = "Hello, post-quantum?";
my $invalid = sphincs_shake128f_verify($signature, $message2, $pk);
ok(!$invalid, 'Signature is invalid');

done_testing();
