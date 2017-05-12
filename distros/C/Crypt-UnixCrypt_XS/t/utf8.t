use Test::More tests => 15;

BEGIN { use_ok "Crypt::UnixCrypt_XS", qw(
		crypt crypt_rounds fold_password
		base64_to_block block_to_base64
		base64_to_int24 int24_to_base64
		base64_to_int12 int12_to_base64
); }

my $tstr = "foo\xaabar!";
my $bstr = "foo\x{100}bar!";

eval { crypt($bstr, "ab"); };
like $@, qr/\Ainput must contain only octets\b/;
eval { crypt($tstr, "a\x{100}"); };
like $@, qr/\Ainput must contain only octets\b/;
eval { crypt_rounds($bstr, 25, 25, $tstr); };
like $@, qr/\Ainput must contain only octets\b/;
eval { crypt_rounds($tstr, 25, 25, $bstr); };
like $@, qr/\Ainput must contain only octets\b/;
eval { fold_password($bstr); };
like $@, qr/\Ainput must contain only octets\b/;
eval { base64_to_block($bstr); };
like $@, qr/\Ainput must contain only octets\b/;
eval { block_to_base64($bstr); };
like $@, qr/\Ainput must contain only octets\b/;
eval { base64_to_int24($bstr); };
like $@, qr/\Ainput must contain only octets\b/;
eval { base64_to_int12($bstr); };
like $@, qr/\Ainput must contain only octets\b/;

SKIP: {
	my $ustr;
	eval {
		require Encode;
		$ustr = Encode::encode_utf8($tstr);
		Encode::_utf8_on($ustr);
	};
	skip "Encode not available", 5 unless $@ eq "";
	is crypt($ustr, "ab"), crypt($tstr, "ab");
	is crypt_rounds($ustr, 25, 25, $ustr),
		crypt_rounds($tstr, 25, 25, $tstr);
	is fold_password($ustr), fold_password($tstr);
	is fold_password($ustr.$ustr), fold_password($tstr.$tstr);
	is block_to_base64($ustr), block_to_base64($tstr);
}
