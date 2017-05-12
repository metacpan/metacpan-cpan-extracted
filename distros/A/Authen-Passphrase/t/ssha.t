use warnings;
use strict;

use Test::More tests => 70;

use MIME::Base64 2.21 qw(encode_base64);

BEGIN { use_ok "Authen::Passphrase::SaltedDigest"; }

my $ppr = Authen::Passphrase::SaltedDigest
		->from_rfc2307("{SSHA}Su3QumFIRp1xFfRZ49hwaJmme+r1iVoM");
ok $ppr;
is $ppr->algorithm, "SHA-1";
is $ppr->salt_hex, "f5895a0c";
is $ppr->hash_hex, "4aedd0ba6148469d7115f459e3d8706899a67bea";

my %pprs;
my $i = 0;
while(<DATA>) {
	chomp;
	s/([^ \n]+) ([^ \n]+) *//;
	my($salt_hex, $hash_hex) = ($1, $2);
	my $salt = pack("H*", $salt_hex);
	my $hash = pack("H*", $hash_hex);
	my $ppr = Authen::Passphrase::SaltedDigest
			->new(algorithm => "SHA-1",
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
	is $ppr->as_rfc2307, "{SSHA}".encode_base64($hash.$salt, "");
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
616263 a9993e364706816aba3e25717850c26c9cd0d89d
717765 7cd928d1e6457c57c01f3c9442177fc62cafa56f 0
212121 2fee6a4e9b98f3bd6de8b1960cfb37f8b44d8bb1 1
787878 76cdd1408a02a44687fe87c98f8dc43678c4ef5f foo
707966 b264504de2719cebf898608cf950e1da5f3ae28f supercalifragilisticexpialidocious
