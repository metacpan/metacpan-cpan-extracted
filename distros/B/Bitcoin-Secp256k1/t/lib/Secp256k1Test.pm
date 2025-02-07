package Secp256k1Test;

use v5.10;
use strict;
use warnings;

# https://github.com/bitcoin/bips/blob/master/bip-0143.mediawiki#native-p2wpkh

my $sample_privkey = pack 'H*',
	'619c335025c7f4012e556c2a58b2506e30b8511b53ade95ea316fd8c3286feb9';
my $sample_pubkey = pack 'H*', '025476c2e83188368da1ff3e292e7acafcdb3566bb0ad253f62fc70f07aeee6357';
my $sample_xonly_pubkey = pack 'H*', '5476c2e83188368da1ff3e292e7acafcdb3566bb0ad253f62fc70f07aeee6357';
my $sample_pubkey_unc = pack 'H*',
	'045476c2e83188368da1ff3e292e7acafcdb3566bb0ad253f62fc70f07aeee6357fd57dee6b46a6b010a3e4a70961ecf44a40e18b279ec9e9fba9c1dbc64896198';
my $sample_preimage = pack 'H*',
	'0100000096b827c8483d4e9b96712b6713a7b68d6e8003a781feba36c31143470b4efd3752b0a642eea2fb7ae638c36f6252b6750293dbe574a806984b8e4d8548339a3bef51e1b804cc89d182d279655c3aa89e815b1b309fe287d9b2b55d57b90ec68a010000001976a9141d0f172a0ecb48aee1be1f2687d2963ae33f71a188ac0046c32300000000ffffffff863ef3e1a92afbfdb97f31ad0fc7683ee943e9abcf2501590ff8f6551f47e5e51100000001000000';
my $sample_sig = pack 'H*',
	'304402203609e17b84f6a7d30c80bfa610b5b4542f32a8a0d5447a12fb1366d7f01cc44a0220573a954c4518331561406f90300e8f3358f51928d43c212a8caed02de67eebee';
my $sample_bad_sig = pack 'H*',
	'304402203609e17b84f6a7d60c80bfa610b5b4542f32a8a0d5447a12fb1366d7f01cc44a0220573a954c4518331561406f90300e8f3358f51928d43c212a8caed02de67eebee';
my $sample_sig_unn = pack 'H*',
	'304502203609e17b84f6a7d30c80bfa610b5b4542f32a8a0d5447a12fb1366d7f01cc44a022100a8c56ab3bae7ccea9ebf906fcff170cb61b9c3bddb0c7f1133238e5ee9b75553';

my $sample_rand_schnorr = pack 'H*',
	'25d1dff95105f5253c4022f628a996ad3a0d95fbf21d468a1b33f8c160d8f517';
my $sample_sig_schnorr = pack 'H*',
	'f965c1178c3e63a7bad2625bf1674af97b4bae11d373b781902920398c4bdd34e326341213117f9c3df6cbad9cb09e7fc599bd400ed2399d8583ccbb4832914a';
my $sample_bad_sig_schnorr = pack 'H*',
	'f965c1178c3e63a7bad2625bf2674af97b4bae11d373b781902920398c4bdd34e326341213117f9c3df6cbad9cb09e7fc599bd400ed2399d8583ccbb4832914a';

sub test_data
{
	return (
		privkey => $sample_privkey,
		pubkey => $sample_pubkey,
		pubkey_unc => $sample_pubkey_unc,
		xonly_pubkey => $sample_xonly_pubkey,
		preimage => $sample_preimage,
		sig => $sample_sig,
		bad_sig => $sample_bad_sig,
		sig_unn => $sample_sig_unn,
		rand => $sample_rand_schnorr,
		sig_schnorr => $sample_sig_schnorr,
		bad_sig_schnorr => $sample_bad_sig_schnorr,
	);
}

1;

