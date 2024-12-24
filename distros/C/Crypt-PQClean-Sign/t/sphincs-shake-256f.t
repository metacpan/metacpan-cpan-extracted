use Test::More;
use Crypt::PQClean::Sign qw(sphincs_shake256f_keypair sphincs_shake256f_sign sphincs_shake256f_verify);

my ($pk, $sk) = sphincs_shake256f_keypair();
ok(defined $pk && defined $sk, 'Generated key pair');

my $message = "Hello, post-quantum!";
my $signature = sphincs_shake256f_sign($message, $sk);
ok(defined $signature, 'Generated signature');

my $valid = sphincs_shake256f_verify($signature, $message, $pk);
ok($valid, 'Signature is valid');

done_testing();
