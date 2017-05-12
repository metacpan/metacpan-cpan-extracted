use warnings;
use strict;

use Test::More tests => 67;

BEGIN { use_ok "Authen::Passphrase::NTHash"; }

my $ppr = Authen::Passphrase::NTHash->new(passphrase => "wibble");
ok $ppr;
is $ppr->hash, "\x53\xf0\xfa\xe7\xd5\x3b\xbe\x6c".
		"\x90\xf8\x43\xec\xeb\x71\xdc\xa0";
is $ppr->hash_hex, "53f0fae7d53bbe6c90f843eceb71dca0";

$ppr = Authen::Passphrase::NTHash
	->from_crypt('$3$$008152e575f1b34babf315cc4971c15d');
ok $ppr;
is $ppr->hash_hex, "008152e575f1b34babf315cc4971c15d";

$ppr = Authen::Passphrase::NTHash
	->from_crypt('$NT$008152e575f1b34babf315cc4971c15d');
ok $ppr;
is $ppr->hash_hex, "008152e575f1b34babf315cc4971c15d";

$ppr = Authen::Passphrase::NTHash
	->from_rfc2307('{CrYpT}$3$$008152e575f1b34babf315cc4971c15d');
ok $ppr;
is $ppr->hash_hex, "008152e575f1b34babf315cc4971c15d";

$ppr = Authen::Passphrase::NTHash
	->from_rfc2307('{MsNt}008152e575f1b34BABf315cc4971c15d');
ok $ppr;
is $ppr->hash_hex, "008152e575f1b34babf315cc4971c15d";

my %pprs;
my $i = 0;
while(<DATA>) {
	chomp;
	s/([^ \n]+) *//;
	my $hash_hex = $1;
	my $hash = pack("H*", $hash_hex);
	$ppr = Authen::Passphrase::NTHash
		->new(($i++ & 1) ? (hash => $hash) : (hash_hex => $hash_hex));
	ok $ppr;
	is $ppr->hash_hex, lc($hash_hex);
	is $ppr->hash, $hash;
	eval { $ppr->passphrase };
	isnt $@, "";
	is $ppr->as_crypt, "\$3\$\$".lc($hash_hex);
	is $ppr->as_rfc2307, "{MSNT}".lc($hash_hex);
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
31d6cfe0d16ae931b73c59d7e0c089c0
7bc26760a19fc23e0996daa99744ca80 0
69943C5E63B4D2C104DBBCC15138B72B 1
ac8e657f83df82beea5d43bdaf7800cc foo
f5295d5b0a47abecb70ed08bdb6d4e6e supercalifragilisticexpialidocious
