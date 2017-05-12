use warnings;
use strict;

use Test::More tests => 75;

BEGIN { use_ok "Authen::Passphrase::LANManager"; }

my $ppr = Authen::Passphrase::LANManager
		->new(passphrase => "wibble");
ok $ppr;
is $ppr->hash, "\xfa\x19\x61\x43\x0a\x96\xf9\xbe".
		"\xaa\xd3\xb4\x35\xb5\x14\x04\xee";
is $ppr->hash_hex, "fa1961430a96f9beaad3b435b51404ee";

$ppr = Authen::Passphrase::LANManager
		->new(passphrase => "wibblewobble");
ok $ppr;
is $ppr->hash_hex, "8ff3acd71203e5ad12f825806ba3a168";

$ppr = Authen::Passphrase::LANManager
	->from_rfc2307("{LANMAN}f67023e95cc9dc1CAad3b435b51404ee");
ok $ppr;
is $ppr->hash_hex, "f67023e95cc9dc1caad3b435b51404ee";

$ppr = Authen::Passphrase::LANManager
	->from_rfc2307("{LANM}f67023e95cc9dc1CAad3b435b51404ee");
ok $ppr;
is $ppr->hash_hex, "f67023e95cc9dc1caad3b435b51404ee";

my %pprs;
my $i = 0;
while(<DATA>) {
	chomp;
	s/([^ \n]+) *//;
	my $hash_hex = $1;
	my $hash = pack("H*", $hash_hex);
	$ppr = Authen::Passphrase::LANManager
			->new(($i++ & 1) ? (hash_hex => $hash_hex) :
					   (hash => $hash));
	ok $ppr;
	is $ppr->hash_hex, lc($hash_hex);
	is $ppr->hash, $hash;
	is $ppr->first_half->hash, substr($hash, 0, 8);
	is $ppr->second_half->hash, substr($hash, 8, 8);
	eval { $ppr->passphrase }; isnt $@, "";
	eval { $ppr->as_crypt }; isnt $@, "";
	is $ppr->as_rfc2307, "{LANMAN}".lc($hash_hex);
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
aad3b435b51404eeaad3b435b51404ee
25AD3B83FA6627C7AAD3B435B51404EE 0
C2265B23734E0DACAAD3B435B51404EE 1
5bfafbebfb6a0942aad3b435b51404ee foo
f0e963830c0156217887ed3fba9a7ed5 supercalifragi
