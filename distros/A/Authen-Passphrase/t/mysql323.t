use warnings;
use strict;

use Test::More tests => 59;

BEGIN { use_ok "Authen::Passphrase::MySQL323"; }

my $ppr = Authen::Passphrase::MySQL323->new(passphrase => "wibble");
ok $ppr;
is $ppr->hash, "\x1d\x1a\x1e\x8f\x50\xfe\xa4\xe3";
is $ppr->hash_hex, "1d1a1e8f50fea4e3";

my %pprs;
my $i = 0;
while(<DATA>) {
	chomp;
	s/([^ \n]+) *//;
	my $hash_hex = $1;
	my $hash = pack("H*", $hash_hex);
	$ppr = Authen::Passphrase::MySQL323
		->new(($i++ & 1) ? (hash => $hash) : (hash_hex => $hash_hex));
	ok $ppr;
	is $ppr->hash_hex, lc($hash_hex);
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
5030573512345671
606717756665BCE6 0
606717496665BCBA 1
7c786c222596437b foo
6873f3091d7dad18 supercalifragilisticexpialidocious
