use Test::More;
use Crypt::PQClean::Sign qw(falcon1024_keypair falcon1024_sign falcon1024_verify);

my ($pk, $sk) = falcon1024_keypair();
ok(defined $pk && defined $sk, 'Generated key pair');

my $message = "Hello, post-quantum!";
my $signature = falcon1024_sign($message, $sk);
ok(defined $signature, 'Generated signature');

my $valid = falcon1024_verify($signature, $message, $pk);
ok($valid, 'Signature is valid');

done_testing();
