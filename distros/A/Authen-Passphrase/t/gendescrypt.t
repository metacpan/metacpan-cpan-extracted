use warnings;
use strict;

use Test::More tests => 71;

BEGIN { use_ok "Authen::Passphrase::DESCrypt"; }

my %pprs;
while(<DATA>) {
	chomp;
	s/([^ \n]+) ([^ \n]+) ([^ \n]+) ([^ \n]+) *//;
	my($nrounds, $salt, $initial, $hash) = ($1, $2, $3, $4);
	my $ppr = Authen::Passphrase::DESCrypt
			->new(fold => 1, initial_base64 => $initial,
			      nrounds_base64 => $nrounds,
			      salt_base64 => $salt, hash_base64 => $hash);
	ok $ppr;
	ok $ppr->fold;
	is $ppr->nrounds_base64_4, $nrounds;
	is $ppr->salt_base64_4, $salt;
	is $ppr->initial_base64, $initial;
	is $ppr->hash_base64, $hash;
	eval { $ppr->passphrase };
	isnt $@, "";
	eval { $ppr->as_crypt };
	isnt $@, "";
	eval { $ppr->as_rfc2307 };
	isnt $@, "";
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
xIw. Alif bXjK3LN9iE2 6UN3gAqtTbM
Eoz. jn35 ACp9yg0cqDM puFoxi30V2o 0
6.d. UyXU yaNPU/4ioNk ZxMRQY8Bpdo 1
Ogc. qu8. YN9krx1eBSE Vcrdw3DtWc6 foo
bAy. XCaN EwD4x5Zn7lY 7KB8x6lwKIQ supercalifragilisticexpialidocious
