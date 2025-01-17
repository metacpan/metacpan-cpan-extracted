use Test::More;
use Crypt::PQClean::Sign qw(mldsa87_keypair mldsa87_sign mldsa87_verify);

my ($pk, $sk) = mldsa87_keypair();
ok(defined $pk && defined $sk, 'Generated key pair');

my $message = "Hello, post-quantum!";
my $signature = mldsa87_sign($message, $sk);
ok(defined $signature, 'Generated signature');

my $valid = mldsa87_verify($signature, $message, $pk);
ok($valid, 'Signature is valid');

my $message2 = "Hello, post-quantum?";
my $invalid = mldsa87_verify($signature, $message2, $pk);
ok(!$invalid, 'Signature is invalid');

done_testing();
