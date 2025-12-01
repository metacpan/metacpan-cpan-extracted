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

subtest 'should die with invalid xonly public key' => sub {
	my $ex = dies { $secp->verify_digest_schnorr("\x12" x 33, $t{sig_schnorr}, "\x12" x 32) };
	like $ex, qr/xonly pubkey must be a bytestring of length 32/, 'exception ok';
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

# cases in api.t are tweaked, use at least one case from a BIP for Schnorr
subtest 'should generate the same signatures as BIP340 test cases' => sub {
	my $priv = pack 'H*', 'b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfef';
	my $pub = pack 'H*', 'dff1d77f2a671c5f36183726db2341be58feae1da2deced843240f7b502ba659';
	my $aux_rand = pack 'H*', '0000000000000000000000000000000000000000000000000000000000000001';
	my $message = pack 'H*', '243f6a8885a308d313198a2e03707344a4093822299f31d0082efa98ec4e6c89';
	my $sig = pack 'H*',
		'6896bd60eeae296db48a229ff71dfe071bde413e6d43f917dc8dcf8c78de33418906d11ac976abccb20b091292bff4ea897efcb639ea871cfa95f6de339e4b0a';

	local $Bitcoin::Secp256k1::FORCED_SCHNORR_AUX_RAND = $aux_rand;
	is $secp->sign_digest_schnorr($priv, $message), $sig, 'digest signed ok';
	ok $secp->verify_digest_schnorr($pub, $sig, $message), 'digest verified ok';
};

subtest 'should fail on undefined value input' => sub {

	# validate first time to populate internal structures
	$secp->verify_message($t{pubkey}, $t{sig}, $t{preimage});

	# check if internal structure value will get emptied with undef
	like dies { $secp->verify_message($t{pubkey}, undef, $t{preimage}) },
		qr{usage: \$secp256k1->verify_message\(\$public_key, \$signature, \$message\)};
	like dies { $secp->verify_message(undef, $t{sig}, $t{preimage}) },
		qr{usage: \$secp256k1->verify_message\(\$public_key, \$signature, \$message\)};
	like dies { $secp->verify_message($t{pubkey}, $t{sig}) },
		qr{usage: \$secp256k1->verify_message\(\$public_key, \$signature, \$message\)};
};

subtest 'should fail on no pubkeys to combine' => sub {
	like dies { $secp->combine_public_keys() },
		qr{usage: \$secp256k1->combine_public_keys\(\$public_key, \[\@more_public_keys\]\)};
	like dies { $secp->combine_public_keys($t{pubkey}, undef) },
		qr{usage: \$secp256k1->combine_public_keys\(\$public_key, \[\@more_public_keys\]\)};
};

done_testing;

