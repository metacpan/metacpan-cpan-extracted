use warnings;
use strict;

use Test::More tests => 59;

BEGIN { use_ok "Authen::Passphrase::MySQL41"; }

my $ppr = Authen::Passphrase::MySQL41->new(passphrase => "wibble");
ok $ppr;
is $ppr->hash, "\xea\x79\x1b\xbc\x44\xf8\x41\x3f\xff\x8c".
		"\x3e\x93\x9f\xe2\x47\x52\xd4\xe8\x4f\xc7";
is $ppr->hash_hex, "EA791BBC44F8413FFF8C3E939FE24752D4E84FC7";

my %pprs;
my $i = 0;
while(<DATA>) {
	chomp;
	s/([^ \n]+) *//;
	my $hash_hex = $1;
	my $hash = pack("H*", $hash_hex);
	$ppr = Authen::Passphrase::MySQL41
		->new(($i++ & 1) ? (hash => $hash) : (hash_hex => $hash_hex));
	ok $ppr;
	is $ppr->hash_hex, uc($hash_hex);
	is $ppr->hash, $hash;
	eval { $ppr->passphrase }; isnt $@, "";
	eval { $ppr->as_crypt }; isnt $@, "";
	eval { $ppr->as_rfc2307 }; isnt $@, "";
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
be1bdec0aa74b4dcb079943e70528096cca985f8
B12289EEF8752AD620294A64A37CD586223AB454 0
E6CC90B878B948C35E92B003C792C46C58C4AF40 1
f3a2a51a9b0f2be2468926b4132313728c250dbf foo
2bbbb6095dced8e931a3dd85dc2c2a039932ed6c supercalifragilisticexpialidocious
