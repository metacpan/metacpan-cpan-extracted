use warnings;
use strict;

use Test::More tests => 63;

BEGIN { use_ok "Authen::Passphrase::LANManagerHalf"; }

my $ppr = Authen::Passphrase::LANManagerHalf
		->new(passphrase => "wibble");
ok $ppr;
is $ppr->hash, "\xfa\x19\x61\x43\x0a\x96\xf9\xbe";
is $ppr->hash_hex, "fa1961430a96f9be";

$ppr = Authen::Passphrase::LANManagerHalf
	->from_crypt('$LM$f67023e95cc9dc1c');
ok $ppr;
is $ppr->hash_hex, "f67023e95cc9dc1c";

$ppr = Authen::Passphrase::LANManagerHalf
	->from_rfc2307('{CRYPT}$LM$f67023e95cc9dc1c');
ok $ppr;
is $ppr->hash_hex, "f67023e95cc9dc1c";

my %pprs;
my $i = 0;
while(<DATA>) {
	chomp;
	s/([^ \n]+) *//;
	my $hash_hex = $1;
	my $hash = pack("H*", $hash_hex);
	$ppr = Authen::Passphrase::LANManagerHalf
			->new(($i++ & 1) ? (hash_hex => $hash_hex) :
					   (hash => $hash));
	ok $ppr;
	is $ppr->hash_hex, lc($hash_hex);
	is $ppr->hash, $hash;
	eval { $ppr->passphrase }; isnt $@, "";
	is $ppr->as_crypt, "\$LM\$".lc($hash_hex);
	is $ppr->as_rfc2307, "{CRYPT}\$LM\$".lc($hash_hex);
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
aad3b435b51404ee
25AD3B83FA6627C7 0
C2265B23734E0DAC 1
5bfafbebfb6a0942 foo
f0e963830c015621 superca
