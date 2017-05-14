#!perl

use Test::More tests => 4;

BEGIN {
    use_ok( 'Crypt::PBC::WIBE' ) || print "Bail out!
";
}

use Crypt::PBC::WIBE;

# Create a new instance, generate public, master secret key
my $wibe = Crypt::PBC::WIBE->new( L => 2 );

# Derive Key for Alice, Bob
my $alice = $wibe->derive(1);
my $bob = $wibe->derive(2);

# Derive Subkey (notice: same ID!) for friend of alice
my $carol = $alice->derive(1);

# Recap: Alice now has the ID vector [1]
# and carol (friend of alice) has [1,1]

# Pattern: Allow all friends (*)
my $pattern = ['*'];

# Create a random element from Crypt::PBC
my $msg = $wibe->pairing->init_GT->random;

my $cipher = $wibe->encrypt_element($pattern, $msg);

ok($alice->decrypt_element($cipher)->is_eq($msg), "Alice should be able to decrypt");
ok($bob->decrypt_element($cipher)->is_eq($msg), "Bob should be able to decrypt");
ok(!$carol->decrypt_element($cipher)->is_eq($msg), "Carol must be unable to decrypt");
