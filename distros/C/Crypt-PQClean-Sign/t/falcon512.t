use Test::More;
use Crypt::PQClean::Sign qw(falcon512_keypair falcon512_sign falcon512_verify);

my ($pk, $sk) = falcon512_keypair();
ok(defined $pk && defined $sk, 'Generated key pair');

my $message = "Hello, post-quantum!";
my $signature = falcon512_sign($message, $sk);
ok(defined $signature, 'Generated signature');

my $valid = falcon512_verify($signature, $message, $pk);
ok($valid, 'Signature is valid');

done_testing();
