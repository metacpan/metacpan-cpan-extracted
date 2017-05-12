use Test::More tests => 8;

BEGIN { use_ok "Crypt::UnixCrypt_XS", qw(
		crypt crypt_rounds fold_password
		base64_to_block block_to_base64
		base64_to_int24 int24_to_base64
		base64_to_int12 int12_to_base64
); }

is crypt("password", "ab"),
	"ab".block_to_base64(crypt_rounds("password", 25,
			base64_to_int12("ab"), "\0\0\0\0\0\0\0\0"));

is crypt("password", "ab"),
	"ab".block_to_base64(crypt_rounds("password", 13,
		base64_to_int12("ab"),
		crypt_rounds("password", 12,
			base64_to_int12("ab"), "\0\0\0\0\0\0\0\0")));

is crypt("long passphrase ***", "_ab..abcd"),
	crypt(fold_password("long passphrase ***"), "_ab..abcd");

is crypt("long passphrase ***", "_ab..abcd"),
	"_ab..abcd".block_to_base64(crypt_rounds(
			fold_password("long passphrase ***"),
			base64_to_int24("ab.."),
			base64_to_int24("abcd"),
			"\0\0\0\0\0\0\0\0"));

is base64_to_block(block_to_base64("\0a\x{80}bcdef")), "\0a\x{80}bcdef";
is base64_to_int24(int24_to_base64(12345678)), 12345678;
is base64_to_int12(int12_to_base64(1234)), 1234;

__DATA__
