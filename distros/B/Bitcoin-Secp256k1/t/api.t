use Test2::V0;
use Bitcoin::Secp256k1;
use Digest::SHA qw(sha256);

use lib 't/lib';
use Secp256k1Test;

################################################################################
# This tests whether high level Perl API is working correctly.
################################################################################

my $secp = Bitcoin::Secp256k1->new;
my %t = Secp256k1Test->test_data;

subtest 'should verify a private key' => sub {
	ok $secp->verify_private_key("\x12" x 32), 'verification ok';
	ok !$secp->verify_private_key("\xff" x 32), 'larger than curve order ok';
	ok !$secp->verify_private_key("\x12" x 31), 'not 32 bytes ok';
};

subtest 'should verify a public key' => sub {
	ok $secp->verify_public_key("\x02" . ("\x12" x 32)), 'verification ok';
	ok !$secp->verify_public_key("\x02" . ("\xff" x 32)), 'larger than curve order ok';
	ok !$secp->verify_public_key("\x02" . ("\x12" x 30)), 'bad length ok';
};

subtest 'should derive a public key' => sub {
	is $secp->create_public_key($t{privkey}), $t{pubkey}, 'pubkey derived ok';
};

subtest 'should compress a public key' => sub {
	is $secp->compress_public_key($t{pubkey_unc}), $t{pubkey}, 'pubkey compressed ok';
	is $secp->compress_public_key($t{pubkey}), $t{pubkey}, 'compressed pubkey intact ok';

	is $secp->compress_public_key($t{pubkey}, 0), $t{pubkey_unc}, 'pubkey uncompressed ok';
	is $secp->compress_public_key($t{pubkey_unc}, 0), $t{pubkey_unc}, 'uncompressed pubkey intact ok';
};

subtest 'should normalize a signature' => sub {
	is $secp->normalize_signature($t{sig_unn}), $t{sig}, 'signature normalized ok';
	is $secp->normalize_signature($t{sig}), $t{sig}, 'normalized signature intact ok';
};

subtest 'should sign and verify a message' => sub {
	is $secp->sign_message($t{privkey}, $t{preimage}), $t{sig}, 'message signed ok';
	ok $secp->verify_message($t{pubkey}, $t{sig}, $t{preimage}), 'message verified ok';
	ok !$secp->verify_message($t{pubkey}, $t{bad_sig}, $t{preimage}), 'bad signature ok';
	ok $secp->verify_message($t{pubkey}, $t{sig_unn}, $t{preimage}), 'unnormalized signature verified ok';
};

subtest 'should sign and verify a message (schnorr)' => sub {
	local $Bitcoin::Secp256k1::FORCED_SCHNORR_AUX_RAND = $t{rand};
	is $secp->sign_message_schnorr($t{privkey}, $t{preimage}), $t{sig_schnorr}, 'message signed ok';
	ok $secp->verify_message_schnorr($t{xonly_pubkey}, $t{sig_schnorr}, $t{preimage}), 'message verified ok';
	ok !$secp->verify_message_schnorr($t{xonly_pubkey}, $t{bad_sig_schnorr}, $t{preimage}), 'bad signature ok';
};

subtest 'should sign and verify a digest' => sub {
	is $secp->sign_digest($t{privkey}, sha256(sha256($t{preimage}))), $t{sig}, 'digest signed ok';
	ok $secp->verify_digest($t{pubkey}, $t{sig}, sha256(sha256($t{preimage}))), 'digest verified ok';
	ok !$secp->verify_digest($t{pubkey}, $t{bad_sig}, sha256(sha256($t{preimage}))), 'digest verified ok';
	ok $secp->verify_digest($t{pubkey}, $t{sig_unn}, sha256(sha256($t{preimage}))),
		'unnormalized signature verified ok';
};

subtest 'should sign and verify a digest (schnorr)' => sub {
	local $Bitcoin::Secp256k1::FORCED_SCHNORR_AUX_RAND = $t{rand};
	is $secp->sign_digest_schnorr($t{privkey}, sha256($t{preimage})), $t{sig_schnorr}, 'digest signed ok';
	ok $secp->verify_digest_schnorr($t{xonly_pubkey}, $t{sig_schnorr}, sha256($t{preimage})), 'digest verified ok';
	ok !$secp->verify_digest_schnorr($t{xonly_pubkey}, $t{bad_sig_schnorr}, sha256($t{preimage})),
		'bad signature ok';
};

subtest 'should sign and verify a message (schnorr) with auxiliary randomness' => sub {
	my $sig = $secp->sign_message_schnorr($t{privkey}, $t{preimage});
	isnt $sig, $t{sig_schnorr}, 'message signed ok';
	ok $secp->verify_message_schnorr($t{xonly_pubkey}, $sig, $t{preimage}), 'message verified ok';
};

subtest 'should get a xonly public key' => sub {
	is $secp->xonly_public_key($t{pubkey}), $t{xonly_pubkey}, 'xonly public key ok';
};

subtest 'should negate' => sub {
	my $negated_pubkey = pack 'H*', '035476c2e83188368da1ff3e292e7acafcdb3566bb0ad253f62fc70f07aeee6357';
	my $negated_privkey = pack 'H*', '9e63ccafda380bfed1aa93d5a74daf9089f68bcb5b9ab6dd1cbb61009daf4288';

	is $secp->negate_public_key($t{pubkey}), $negated_pubkey, 'negated pubkey ok';
	is $secp->negate_private_key($t{privkey}), $negated_privkey, 'negated privkey ok';
};

subtest 'should add' => sub {
	my $added_pubkey = pack 'H*', '0260213f6d967636c54d8845c23098e0f63d906b7903d23692efa155a155eda169';
	my $added_privkey = pack 'H*', '67a239562bcdfa07345b72305eb8567436be572159b3ef64a91d0392388d04bf';
	my $tweak = "\x06" x 32;

	is $secp->add_public_key($t{pubkey}, $tweak), $added_pubkey, 'added pubkey ok';
	is $secp->add_private_key($t{privkey}, $tweak), $added_privkey, 'added privkey ok';
};

subtest 'should multiply' => sub {
	my $multiplied_pubkey = pack 'H*', '0311ab47c9252066f0ca5946d70c3aaac1486d65969b90cd57207476963c9f9af3';
	my $multiplied_privkey = pack 'H*', '2d40a33515eb26b0fbce29e0e9645e15d6ff4892a17e59ab31b66b496780a683';
	my $tweak = "\x06" x 32;

	is $secp->multiply_public_key($t{pubkey}, $tweak), $multiplied_pubkey, 'multiplied pubkey ok';
	is $secp->multiply_private_key($t{privkey}, $tweak), $multiplied_privkey, 'multiplied privkey ok';
};

subtest 'should combine one pubkey into itself' => sub {
	is $secp->combine_public_keys($t{pubkey}), $t{pubkey}, 'combined pubkey ok';
};

subtest 'should combine multiple pubkeys' => sub {
	my @to_combine = (
		pack('H*', '0311ab47c9252066f0ca5946d70c3aaac1486d65969b90cd57207476963c9f9af3'),
		pack('H*', '0260213f6d967636c54d8845c23098e0f63d906b7903d23692efa155a155eda169'),
	);
	my $combined_pubkey = pack 'H*', '0255c3386d6833d5e1ad6d863afc1cf5d8ffdc0ebc78e4241e845a6c2cbd78157b';

	is $secp->combine_public_keys($t{pubkey}, @to_combine), $combined_pubkey, 'combined pubkey ok';
};

subtest 'should sign and verify a message (recoverable)' => sub {
	my $rec_sig = $secp->sign_message_recoverable($t{privkey}, $t{preimage});
	ok defined($rec_sig), 'recoverable message signed ok';

	ok defined($rec_sig->{signature}), 'compact signature extracted ok';
	ok defined($rec_sig->{recovery_id}), 'recovery id extracted ok';
	is length($rec_sig->{signature}), 64, 'compact signature length ok';
	ok $rec_sig->{recovery_id} >= 0 && $rec_sig->{recovery_id} <= 3, 'recovery id range ok';

	# Test recovery
	my $recovered_pubkey = $secp->recover_public_key_message($rec_sig, $t{preimage});
	is $recovered_pubkey, $t{pubkey}, 'public key recovered from message ok';

	# Test verification methods
	ok $secp->verify_message_recoverable($t{pubkey}, $rec_sig, $t{preimage}), 'recoverable message verified ok';

	# Test with wrong pubkey should fail
	my $wrong_pubkey = pack 'H*', '025476c2e83188368da1ff3e292e7acafcdb3566bb0ad253f62fc70f07aeee6358';
	ok !$secp->verify_message_recoverable($wrong_pubkey, $rec_sig, $t{preimage}),
		'wrong pubkey verification fails ok';
};

subtest 'should sign and verify a digest (recoverable)' => sub {
	my $digest = sha256(sha256($t{preimage}));
	my $rec_sig = $secp->sign_digest_recoverable($t{privkey}, $digest);
	ok defined($rec_sig), 'recoverable digest signed ok';

	# Test recovery
	my $recovered_pubkey = $secp->recover_public_key_digest($rec_sig, $digest);
	is $recovered_pubkey, $t{pubkey}, 'public key recovered from digest ok';

	# Test verification
	ok $secp->verify_digest_recoverable($t{pubkey}, $rec_sig, $digest), 'recoverable digest verified ok';

	# Test with bad digest should fail
	my $bad_digest = $digest;
	substr($bad_digest, 0, 1) = "\xff";
	ok !$secp->verify_digest_recoverable($t{pubkey}, $rec_sig, $bad_digest),
		'wrong digest verification fails ok';
};

# https://ethereum.github.io/yellowpaper/paper.pdf
# Appendix F. Signing Transactions
subtest 'ethereum yellowpaper specification' => sub {
	my @test_cases = (
		{
			name => 'pk1 recoverable case',
			privkey => pack('H*', '0000000000000000000000000000000000000000000000000000000000000001'),
			message => pack('H*', '0000000000000000000000000000000000000000000000000000000000000001'),
		},
		{
			name => 'pk2 recoverable case',
			privkey => pack('H*', '4646464646464646464646464646464646464646464646464646464646464646'),
			message => pack('H*', '9c22ff5f21f0b81b113e63f7db6da94fedef11b2119b4088b89664fb9a3cb658'),
		},
	);

	for my $case (@test_cases) {
		subtest $case->{name} => sub {
			my $rec_sig = $secp->sign_digest_recoverable($case->{privkey}, $case->{message});

			# Yellowpaper constraint: v ∈ {0, 1}
			my $v = $rec_sig->{recovery_id};
			ok $v >= 0 && $v <= 1, 'v in valid range [0,1]';

			# Test recovery
			my $recovered_pubkey = $secp->recover_public_key_digest($rec_sig, $case->{message});
			my $original_pubkey = $secp->create_public_key($case->{privkey});
			is $recovered_pubkey, $original_pubkey, 'recovery matches original';

			# Test message-level recovery
			my $rec_sig_msg = $secp->sign_message_recoverable($case->{privkey}, $case->{message});
			my $recovered_pubkey_msg = $secp->recover_public_key_message($rec_sig_msg, $case->{message});
			is $recovered_pubkey_msg, $original_pubkey, 'message recovery matches original';
		};
	}
};

done_testing;

