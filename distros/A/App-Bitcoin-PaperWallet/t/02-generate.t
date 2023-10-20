use v5.12;
use warnings;

use Test::More;
use App::Bitcoin::PaperWallet;

subtest 'should generate mnemonic from fixed entropy' => sub {
	my $hash = App::Bitcoin::PaperWallet->generate('silly entropy that should never be used in a real wallet', 'sillypass');

	# seed should be 76f30b114cb9165116a9b0a9e214e3ea4cfa9923adc8154e5d72b12e54b5a20a
	is $hash->{mnemonic}, 'ivory obscure session offer multiply chuckle follow current prepare awful decline stand soul erode modify ribbon best indicate frequent girl torch food market evidence', 'mnemonic ok';

	# those addresses take password into account
	is $hash->{addresses}[0], '3QUyruDJ9oce8KNJELPWAxfcvcvESuGrds', 'compat address ok';
	is $hash->{addresses}[1], 'bc1qngdesm3ljdfyxsskvsxz4034vlyk9cjm7r6k5p', 'native address 1 ok';
	is $hash->{addresses}[2], 'bc1qp67k9ztxp5gycvt3pc8cxm0ssha226sqe338q8', 'native address 2 ok';
	is $hash->{addresses}[3], 'bc1qlz5an57pfxr4aewes8shhk8p8uglhs0x7czwuj', 'native address 3 ok';

	is scalar @{$hash->{addresses}}, 4, 'address count ok';

	# test data generated using https://iancoleman.io/bip39/
};

subtest 'should generate mnemonic from random entropy' => sub {
	my $hash = App::Bitcoin::PaperWallet->generate(undef, 'pass');

	ok defined $hash->{mnemonic}, 'mnemonic defined ok';
	my @words = split / /, $hash->{mnemonic};
	is scalar @words, 24, 'word count ok';

	note "Generated mnemonic: $hash->{mnemonic}";
};

done_testing;

