use Test2::V0;
use App::Bitcoin::PaperWallet;

subtest 'should generate mnemonic from fixed entropy' => sub {
	my $hash = App::Bitcoin::PaperWallet->generate('silly entropy that should never be used in a real wallet', 'sillypass');

	# seed should be 76f30b114cb9165116a9b0a9e214e3ea4cfa9923adc8154e5d72b12e54b5a20a
	is $hash->{mnemonic}, 'ivory obscure session offer multiply chuckle follow current prepare awful decline stand soul erode modify ribbon best indicate frequent girl torch food market evidence', 'mnemonic ok';

	# those addresses take password into account
	is $hash->{addresses}[0], '3QUyruDJ9oce8KNJELPWAxfcvcvESuGrds', 'compat address ok';
	is $hash->{addresses}[1], 'bc1pje8edfynd2n8rs0y2sex9kqne6ehsj45lye0zle0ku0wejae2vjs0v3djk', 'taproot address 1 ok';
	is $hash->{addresses}[2], 'bc1pwxk5alqt64dzc6dgw3llc6scny6mnax2glpac2h2wltpcstuxafqeq729s', 'taproot address 2 ok';
	is $hash->{addresses}[3], 'bc1px8rnyf54uvxk7y84mzx4f6unmvz2090tqyduel3qrvurwn37t4js4j44yg', 'taproot address 3 ok';

	is scalar @{$hash->{addresses}}, 4, 'address count ok';

	# test data generated using https://gugger.guru/cryptography-toolkit/#!/hd-wallet
};

subtest 'should generate shorter mnemonic from fixed entropy and no compat addresses' => sub {
	my $hash = App::Bitcoin::PaperWallet->generate('silly entropy that should never be used in a real wallet', 'sillypass', {
		compat_addresses => 0,
		entropy_length => 160,
	});

	# seed should be 76f30b114cb9165116a9b0a9e214e3ea4cfa9923
	is $hash->{mnemonic}, 'ivory obscure session offer multiply chuckle follow current prepare awful decline stand soul erode misery', 'mnemonic ok';

	# those addresses take password into account
	is $hash->{addresses}[0], 'bc1p9x80amyegmhe5nt84w74ghgkt2mgkd9503gdkzh9g4lefq2saraq8yuze0', 'taproot address 1 ok';
	is $hash->{addresses}[1], 'bc1pyrtljkh9cggs6m7kwykr22zsx4fq26z5a0sfvv5jaq3jc350nelsmkxjtl', 'taproot address 2 ok';
	is $hash->{addresses}[2], 'bc1pmwd0g8cye0r3dhmr7dvwcjcqhz943p4vx0z28d8pptjpuqq827dqyhk3kp', 'taproot address 3 ok';

	is scalar @{$hash->{addresses}}, 3, 'address count ok';

	# test data generated using https://gugger.guru/cryptography-toolkit/#!/hd-wallet
};

subtest 'should generate shorter mnemonic from fixed entropy and only segwit addresses' => sub {
	my $hash = App::Bitcoin::PaperWallet->generate('silly entropy that should never be used in a real wallet', 'sillypass', {
		compat_addresses => 0,
		segwit_addresses => 3,
		taproot_addresses => 0,
		entropy_length => 160,
	});

	# seed should be 76f30b114cb9165116a9b0a9e214e3ea4cfa9923
	is $hash->{mnemonic}, 'ivory obscure session offer multiply chuckle follow current prepare awful decline stand soul erode misery', 'mnemonic ok';

	# those addresses take password into account
	is $hash->{addresses}[0], 'bc1qqns5u7ek4dhsg0x3q6dfrsdqqdy5gtgnrzplar', 'native address 1 ok';
	is $hash->{addresses}[1], 'bc1qvpkk52g7fm64l482eln3unf659epqhtpcqt3hm', 'native address 2 ok';
	is $hash->{addresses}[2], 'bc1qyq9sanwvrd300erymsln58myar55fr2cldmcgx', 'native address 3 ok';

	is scalar @{$hash->{addresses}}, 3, 'address count ok';

	# test data generated using https://iancoleman.io/bip39/
};

subtest 'should generate mnemonic from random entropy' => sub {
	my $hash = App::Bitcoin::PaperWallet->generate(undef, 'pass');

	ok defined $hash->{mnemonic}, 'mnemonic defined ok';
	my @words = split / /, $hash->{mnemonic};
	is scalar @words, 24, 'word count ok';

	note "Generated mnemonic: $hash->{mnemonic}";
};

subtest 'invalid network should throw exception' => sub {
	my $ex = dies {
		my $hash = App::Bitcoin::PaperWallet->generate(undef, 'pass', {
			network => 'invalid',
		});
	};

	like $ex, qr/network invalid is not registered/, 'exception thrown ok';
};

subtest 'valid, non-default network should not throw exception' => sub {
	my $hash;
	my $lived = lives {
		$hash = App::Bitcoin::PaperWallet->generate(undef, 'pass', {
			network => 'dogecoin',
			segwit_addresses => 2,
			compat_addresses => 3,
			taproot_addresses => 1,
		});
	};

	ok $lived, 'no exception ok';
	ok defined $hash, 'returned value defined ok';
	is scalar @{ $hash->{addresses} }, 6, 'generating the same number of legacy addresses as would for a segwit network';
};

done_testing;

