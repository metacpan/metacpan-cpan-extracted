use warnings;
use strict;

use Test::More tests => 81;

use MIME::Base64 2.21 qw(encode_base64);

BEGIN { use_ok "Authen::Passphrase::SaltedDigest"; }

my $ppr = Authen::Passphrase::SaltedDigest
		->from_rfc2307("{SMD5}1NdYklP8pSDsgowfOxOK7/x4sUA=");
ok $ppr;
is $ppr->algorithm, "MD5";
is $ppr->salt_hex, "fc78b140";
is $ppr->hash_hex, "d4d7589253fca520ec828c1f3b138aef";

$ppr = Authen::Passphrase::SaltedDigest
		->new(algorithm => "Digest::MD5-1.99_53", salt => "NaCl",
		      passphrase => "wibble");
ok $ppr;
is $ppr->salt, "NaCl";
is $ppr->salt_hex, "4e61436c";
is $ppr->hash, "\x04\xbd\x9d\x36\xc5\xc5\x49\x79".
		"\x84\xa2\x67\x0e\xd2\x44\x2f\x9d";
is $ppr->hash_hex, "04bd9d36c5c5497984a2670ed2442f9d";
like $ppr->as_rfc2307, qr/\A\{SMD5\}/;

$ppr = Authen::Passphrase::SaltedDigest
		->new(algorithm => "MD5", salt_random => 13,
		      passphrase => "wibble");
ok $ppr;
is length($ppr->salt), 13;
is length($ppr->hash), 16;
like $ppr->as_rfc2307, qr/\A\{SMD5\}/;
ok $ppr->match("wibble");

my %pprs;
my $i = 0;
while(<DATA>) {
	chomp;
	s/([^ \n]+) ([^ \n]+) *//;
	my($salt_hex, $hash_hex) = ($1, $2);
	my $salt = pack("H*", $salt_hex);
	my $hash = pack("H*", $hash_hex);
	$ppr = Authen::Passphrase::SaltedDigest
			->new(algorithm => "MD5",
			      ($i & 1) ? (salt => $salt) :
					 (salt_hex => $salt_hex),
			      ($i & 2) ? (hash => $hash) :
					 (hash_hex => $hash_hex));
	$i++;
	ok $ppr;
	is $ppr->salt_hex, $salt_hex;
	is $ppr->salt, $salt;
	is $ppr->hash_hex, $hash_hex;
	is $ppr->hash, $hash;
	eval { $ppr->passphrase }; isnt $@, "";
	eval { $ppr->as_crypt }; isnt $@, "";
	is $ppr->as_rfc2307, "{SMD5}".encode_base64($hash.$salt, "");
	$pprs{$_} = $ppr;
}

foreach my $rightphrase (sort keys %pprs) {
	my $ppr = $pprs{$rightphrase};
	foreach my $passphrase (sort keys %pprs) {
		ok ($ppr->match($passphrase) xor $passphrase ne $rightphrase);
	}
}

1;

__DATA__
616263 900150983cd24fb0d6963f7d28e17f72
717765 ce97e12b13baef6403b5456f8fc2ce99 0
212121 b097f957c235fd286364dc2084b2546d 1
787878 097412258a515fc61cfe73f421f58b8f foo
707966 c676f3ddf4b4ed188a89d73525ff678e supercalifragilisticexpialidocious
