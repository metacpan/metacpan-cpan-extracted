#!perl

use Test::More tests => 40;

BEGIN {
    use_ok( 'Crypt::PBC::WIBE' ) || print "Bail out!
";
}

use Crypt::PBC::WIBE;

my $wibe = Crypt::PBC::WIBE->new(L => 2);
my $pairing = $wibe->pairing;

# Ensure keys are generated
for (qw(SK MPK DSK)) {
	ok(defined $wibe->{$_}, "'$_' should be defined in a new WIBE instance");
}

is scalar(keys $wibe->{DSK}->{key}), 4, 'secret key length master instance is correct';

# Derive 3 friends and a subkey for myself (0)
my @users = map { $wibe->derive($_) } 0..3;
my $friend_of_1 = $users[1]->derive(1);

for my $uid (0..3) {
	is_deeply $users[$uid]->{MPK}, $wibe->{MPK}	, 'MPK is unaltered';
	is_deeply $users[$uid]->{DSK}->{ids}, [$uid], 'Set DSK hierarchy is correct';

	is scalar(keys $users[$uid]->{DSK}->{key}), 3, 'derivable secret key length of friends is correct';
	is scalar(@{$users[$uid]->{SK}->{ids}}), 2, 'ID vector length of friends\' SK is correct';
}
is scalar(@{$friend_of_1->{SK}->{ids}}), 2, 'ID vector length of friends is correct';

# 1. Pattern: Myself
{
	my $P = [0,0];

	# Choose random message
	my $m = $pairing->init_GT->random;
	my $ct = $wibe->encrypt_element($P, $m);

	my $dec = $users[0]->decrypt_element($ct);
	ok ($m->is_eq($dec), "Decryption for [0,0] with ID[1] = 0 should work");

	ok (!$m->is_eq($users[$_]->decrypt_element($ct)), "Decryption for [0,0] with ID[1] = $_ should fail")
	for (1..3);
}


# 2. Pattern: One friend
{
	my $P = [1,0];

	# Choose random message
	my $m = $pairing->init_GT->random;
	my $ct = $wibe->encrypt_element($P, $m);

	# The first pattern should only work for id=1 and the master key
	my $dec = $users[1]->decrypt_element($ct);
	ok ($m->is_eq($dec), "Decryption for [1,0] with ID[1] = 1 should work");

	ok (!$m->is_eq($users[$_]->decrypt_element($ct)), "Decryption for [1,self] with ID[1] = $_ should fail")
	for (qw(0 2 3));
}

# 3. Pattern: Any friend
{
	my $P = ['*',0];

	# Choose random message
	my $m = $pairing->init_GT->random;
	my $ct = $wibe->encrypt_element($P, $m);

	# The first pattern should only work for id=1..3 and the master key
	ok ($m->is_eq($users[$_]->decrypt_element($ct)), "Decryption of [*,self] with ID[1] = $_ should work")
	for 0..3;
	ok (!$m->is_eq($friend_of_1->decrypt_element($ct)), "Decryption of [*,self] with ID = [1,42] should fail");
}

# 4. Pattern: Any friend, FoF
{
	my $P = ['*','*'];

	# Choose random message
	my $m = $pairing->init_GT->random;
	my $ct = $wibe->encrypt_element($P, $m);

	# The first pattern should only work for id=1..3 and the master key
	ok ($m->is_eq($users[$_]->decrypt_element($ct)), "Decryption of [*,*] should work for ID=$_")
	for 0..3;
	ok ($m->is_eq($friend_of_1->decrypt_element($ct)), "Decryption of [*,*] should fail for Friend of 1");
}