use Test2::V0;
use Bitcoin::Secp256k1;

use lib 't/lib';
use Secp256k1Test;

################################################################################
# This tests if all foreseeable edge cases are handled correctly
################################################################################

my $secp = Bitcoin::Secp256k1->new;
my %t = Secp256k1Test->test_data;

subtest 'should die on constructor with arguments' => sub {
	my $ex = dies { Bitcoin::Secp256k1->new('argument') };
	like $ex, qr/\QUsage: Bitcoin::Secp256k1::new(classname)\E/, 'exception ok';
};

subtest 'should die on low level methods without constructed object' => sub {
	my $ex = dies { Bitcoin::Secp256k1->_pubkey };
	like $ex, qr/calling Bitcoin::Secp256k1 methods is only valid in object context/, 'exception ok';
};

subtest 'should die on high level methods without constructed object' => sub {
	my $ex = dies { Bitcoin::Secp256k1->create_public_key("\x12" x 32) };
	like $ex, qr/calling Bitcoin::Secp256k1 methods is only valid in object context/, 'exception ok';
};

subtest 'should die with reference private key' => sub {
	my $ex = dies { $secp->create_public_key([]) };
	like $ex, qr/private key must be a bytestring of length 32/, 'exception ok';
};

subtest 'should die with invalid length private key' => sub {
	my $ex;

	$ex = dies { $secp->create_public_key("\x12" x 31) };
	like $ex, qr/private key must be a bytestring of length 32/, 'too short ok';

	$ex = dies { $secp->create_public_key("\x12" x 33) };
	like $ex, qr/private key must be a bytestring of length 32/, 'too long ok';
};

subtest 'should die with invalid public key' => sub {
	my $ex = dies { $secp->verify_digest("\x12" x 65, $t{sig}, "\x12" x 32) };
	like $ex, qr/the input does not appear to be a valid public key/, 'exception ok';
};

subtest 'should die with invalid signature' => sub {
	my $ex = dies { $secp->verify_digest($t{pubkey}, "\x12" x 65, "\x12" x 32) };
	like $ex, qr/the input does not appear to be a valid signature/, 'exception ok';
};

subtest 'should die with invalid digest' => sub {
	my $ex = dies { $secp->verify_digest($t{pubkey}, $t{sig}, "\x12" x 35) };
	like $ex, qr/digest must be a bytestring of length 32/, 'exception ok';
};

subtest 'should die on invalid addition' => sub {
	my $negated = $secp->negate_private_key($t{privkey});
	my $ex = dies { $secp->add_private_key($t{privkey}, $negated) };
	like $ex, qr/resulting added privkey is not valid/, 'exception ok';
};

subtest 'should die on invalid multiplication' => sub {
	my $ex = dies { $secp->multiply_public_key($t{pubkey}, "\xff" x 32) };
	like $ex, qr/multiplication arguments are not valid/, 'exception ok';
};

subtest 'should die on invalid combination of public keys' => sub {
	my $ex = dies { $secp->combine_public_keys($t{pubkey}, "\02" . "\xff" x 32) };
	like $ex, qr/the input does not appear to be a valid public key/, 'exception ok';
};

done_testing;

