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
	ok !$secp->verify_private_key("\xff" x 31), 'not 32 bytes ok';
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

	is warns {
		ok $secp->verify_message($t{pubkey}, $t{sig_unn}, $t{preimage}), 'unnormalized signature verified ok';
	}, 1, 'unnormalized signature warning ok';
};

subtest 'should sign and verify a digest' => sub {
	is $secp->sign_digest($t{privkey}, sha256(sha256($t{preimage}))), $t{sig}, 'digest signed ok';
	ok $secp->verify_digest($t{pubkey}, $t{sig}, sha256(sha256($t{preimage}))), 'digest verified ok';

	is warns {
		ok $secp->verify_digest($t{pubkey}, $t{sig_unn}, sha256(sha256($t{preimage}))),
			'unnormalized signature verified ok';
	}, 1, 'unnormalized signature warning ok';
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

done_testing;

