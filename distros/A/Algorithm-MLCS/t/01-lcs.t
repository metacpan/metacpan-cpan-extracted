#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Algorithm::MLCS;

plan tests => 6;

ok(test_lcs());
ok(rand_test_lcs());
ok(rand_test_lcs());
ok(rand_test_lcs());
ok(rand_test_lcs());
ok(rand_test_lcs());

sub test_lcs {
	my @seq = qw(
		22ef32d6c3a532e623858a64818933e84962ca59f068079513f00d0fb2efeba3d621a101ebb4d4eb2f98dbfc77890e7e4c3db3a7d8e9ff1bcab0d911e19381188e7e125bcf811e3f0b5408917a1ca457f4577fb195ec305500cdda1f03aaacf63dfc309a3
		978026c4d8bdd501e08fbe5d4dc34c458d6a28d2c5017d50055c879449e9827ab890cdf67823f50a2c1ecf8f4713eb8ed3e8ac537f1db1aad57dddab015652949ff29bb8810c49cb888cb454639ac7e1ba236774416a3b3ae428ffbb2790d7135d36ab573
		9f53d484e85975d57324fd0c3151b9e4c8af7e9d47a2d1c23b84212127a591c875ed3700995a1f37c675ace63658c306bcfca9aa2bcff972a1473a15169eb6449ecfe8b3686bf14b2aa081b3b692d10590976e37314fb92e5d823d6852d5a0c0aac0bb57b
		131012988f9e4c7f7d09c0a5933aadfe55a5d5c1b11b4eced9f93e98d244e0ced39df9a0075ab9375ecb6783cc522516f7b91caf87796c403214d489c4dd39a081afe23f99e0ee8d3213bd481ad05948903675a786e6b028713b5046fd5604206934c8628
		7f2270742532e612b20ae2d366e5b14909ca97347e068d68588041ee6466f134801057b5828bb0802b9242461c979e1f1d309d952b732950763c3669ccd7b9849738e812f056904eb5d63c72cdf40f6db997fabec39e984e37552c87a6e1a17cee9308249
		108724279e2b9f3af15254efcab45ac9f0d48c403cf7af2d947ebf1ca0e871dc1a85cbd34839d1abdb9be635d426dd39c1100fb0d5b60eeb942ece53a90ccf2c3e062ded80174da445cdd60801c5ac72d00eda8a4b877f4d8297f8ac871861ec13371653b
		1034ec4a15a38a83713d06df20a4b0d99f60e647c696ebfe1512407271351b10674d1f10ec7a26298c74953252e795c2033f678464d2676fdefc5ba328b26f9fe755451106495314d1a6f2111ae5708cb4afa75209ca3fc39e1f8bd8f00d7a542763cc5ef
		9569d837bbf5b076b8dfb89e476be7b31b25eba4f1339a831ed4db2a6e0167000d1e149a0bf463c12590fb1d29673876ea40ae20f519de9ff338e58f05be4c2027d3b1f354623223a2f16601b2062a048c0b5cc90292a745d38f4ccc8b209e78528ec5287
		15592f479154ac1bc62594198049dc6bd132f67916a7a6debdf12cb84a6483bba23fccd34f6d3b91ffe5e1e5db80fbe94ef0f1a5fa14f74bfe62bc1e4dbde7ff26e759ff895a2332622dbd6985c45b2e1e12411926c66d7a3a867225c043134f34b944f27
		493029da9e22b506bc32e573cbb86e83b033d2c8baff584e3d2503ec17606dfe37f6e579caadd6ab52729129ba522e4e1cb5ffa91f36cea0d04e226735fb3b529c732bd2e4edfb8ef828d82a64b5a012d1e758fa02457d8b6bc45a91090bbe365a80260f2
	);
	my @seq_ref = map { [ split // ] } @seq;
	my @lcs = lcs( \@seq_ref );
	my $lcs_rx = join("\\w*", @lcs);
	my $match_cnt = 0;
	for ( @seq ) { $match_cnt++ if /$lcs_rx/ }
	return $match_cnt == scalar @seq ? 1 : 0;
}

sub rand_test_lcs {
	my @d = split //, "0123456789abcdef";
	my ($NUM_OF_SEQS, $SEQ_LEN) = (20, 200);
	my @seq;
	for my $n (0..($NUM_OF_SEQS - 1)) {
		my @c = ();
		for (0..($SEQ_LEN - 1)) { push @c, $d[int(rand @d)] }
		push @seq, \@c;
	}
	my @lcs = lcs( \@seq );
	my $lcs_rx = join("\\w*", @lcs);
	my $match_cnt = 0;
	for ( @seq ) { $match_cnt++ if join("", @$_) =~ /$lcs_rx/ }
	return $match_cnt == $NUM_OF_SEQS ? 1 : 0;
}

