use Test::More;
use Crypt::PQClean::Sign qw(sphincs_shake192s_keypair sphincs_shake192s_sign sphincs_shake192s_verify);

my ($pk, $sk) = sphincs_shake192s_keypair();
ok(defined $pk && defined $sk, 'Generated key pair');

my $message = "Hello, post-quantum!";
my $signature = sphincs_shake192s_sign($message, $sk);
ok(defined $signature, 'Generated signature');

my $valid = sphincs_shake192s_verify($signature, $message, $pk);
ok($valid, 'Signature is valid');

done_testing();
