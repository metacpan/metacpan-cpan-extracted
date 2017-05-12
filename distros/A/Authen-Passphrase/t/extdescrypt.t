use warnings;
use strict;

use Test::More tests => 77;

BEGIN { use_ok "Authen::Passphrase::DESCrypt"; }

my $ppr = Authen::Passphrase::DESCrypt->from_crypt("_cD..NaClP7NemfyIO3Y");
ok $ppr;
ok $ppr->fold;
is $ppr->initial_base64, "...........";
is $ppr->nrounds, 1000;
is $ppr->salt_base64_4, "NaCl";
is $ppr->hash_base64, "P7NemfyIO3Y";

my %pprs;
while(<DATA>) {
	chomp;
	s/([^ \n]+) ([^ \n]+) ([^ \n]+) *//;
	my($nrounds, $salt, $hash) = ($1, $2, $3);
	$ppr = Authen::Passphrase::DESCrypt
			->new(fold => 1, nrounds_base64 => $nrounds,
			      salt_base64 => $salt, hash_base64 => $hash);
	ok $ppr;
	ok $ppr->fold;
	is $ppr->initial_base64, "...........";
	is $ppr->nrounds_base64_4, $nrounds;
	is $ppr->salt_base64_4, $salt;
	is $ppr->hash_base64, $hash;
	eval { $ppr->passphrase };
	isnt $@, "";
	is $ppr->as_crypt, "_".$nrounds.$salt.$hash;
	is $ppr->as_rfc2307, "{CRYPT}_".$nrounds.$salt.$hash;
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
fiO. zjn3 EwD4x5Zn7lY
i9O/ VDnK bXjK3LN9iE2 0
3Ro. TEkq ACp9yg0cqDM 1
I4l. wIO. yaNPU/4ioNk foo
eGu. aKa2 YN9krx1eBSE supercalifragilisticexpialidocious
