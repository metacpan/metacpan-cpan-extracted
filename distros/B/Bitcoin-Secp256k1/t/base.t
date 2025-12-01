use Test2::V0;
use Bitcoin::Secp256k1;
use Digest::SHA qw(sha256);

use lib 't/lib';
use Secp256k1Test;

################################################################################
# This tests whether the most base methods defined in XS are working correctly.
################################################################################

my $secp;
my %t = Secp256k1Test->test_data;

my $partial_digest = sha256($t{preimage});
my $digest = sha256($partial_digest);

subtest 'should create and destroy' => sub {
	$secp = Bitcoin::Secp256k1->new();
	isa_ok $secp, 'Bitcoin::Secp256k1';
};

subtest 'should import and export pubkey' => sub {
	is $secp->_pubkey, undef, 'starting pubkey ok';
	is $secp->_pubkey($t{pubkey}), $t{pubkey}, 'setter ok';
	is $secp->_pubkey, $t{pubkey}, 'getter ok';
	is $secp->_pubkey($t{pubkey}, 1), $t{pubkey}, 'getter with explicit compression ok';
	is $secp->_pubkey($t{pubkey}, 0), $t{pubkey_unc}, 'getter with explicit (un)compression ok';
	is $secp->_pubkey($t{pubkey_unc}), $t{pubkey}, 'setter with uncompressed input, compressed output ok';
	is $secp->_pubkey(undef), undef, 'cleared pubkey ok';
};

subtest 'should import and export xonly pubkey' => sub {
	is $secp->_xonly_pubkey, undef, 'starting xonly pubkey ok';
	is $secp->_xonly_pubkey($t{xonly_pubkey}), $t{xonly_pubkey}, 'setter ok';
	is $secp->_xonly_pubkey, $t{xonly_pubkey}, 'getter ok';
	is $secp->_xonly_pubkey(undef), undef, 'cleared xonly pubkey ok';
};

subtest 'should import and export signature' => sub {
	is $secp->_signature, undef, 'starting sig ok';
	is $secp->_signature($t{sig}), $t{sig}, 'setter ok';
	is $secp->_signature, $t{sig}, 'getter ok';
	is $secp->_signature(undef), undef, 'cleared sig ok';
};

subtest 'should import and export schnorr signature' => sub {
	is $secp->_signature_schnorr, undef, 'starting sig ok';
	is $secp->_signature_schnorr($t{sig_schnorr}), $t{sig_schnorr}, 'setter ok';
	is $secp->_signature_schnorr, $t{sig_schnorr}, 'getter ok';
	is $secp->_signature_schnorr(undef), undef, 'cleared sig ok';
};

subtest 'should normalize a signature' => sub {
	$secp->_signature($t{sig_unn});

	ok $secp->_normalize, 'signature normalized ok';
	is $secp->_signature, $t{sig}, 'signature ok';
	ok !$secp->_normalize, 'already normalized ok';
};

subtest 'should clear the object' => sub {
	$secp->_pubkey($t{pubkey});
	$secp->_xonly_pubkey($t{xonly_pubkey});
	$secp->_signature($t{sig});
	$secp->_signature_schnorr($t{sig_schnorr});

	$secp->_clear;

	is $secp->_pubkey, undef, 'cleared pubkey ok';
	is $secp->_xonly_pubkey, undef, 'cleared xonly pubkey ok';
	is $secp->_signature, undef, 'cleared sig ok';
	is $secp->_signature_schnorr, undef, 'cleared schnorr sig ok';
};

done_testing;

