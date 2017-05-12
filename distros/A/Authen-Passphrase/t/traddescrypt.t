use warnings;
use strict;

use Test::More tests => 77;

BEGIN { use_ok "Authen::Passphrase::DESCrypt"; }

my $ppr = Authen::Passphrase::DESCrypt->from_crypt("UBJcPos7octOA");
ok $ppr;
ok !$ppr->fold;
is $ppr->initial_base64, "...........";
is $ppr->nrounds, 25;
is $ppr->salt_base64_2, "UB";
is $ppr->hash_base64, "JcPos7octOA";

my %pprs;
while(<DATA>) {
	chomp;
	s/([^ \n]+) ([^ \n]+) *//;
	my($salt, $hash) = ($1, $2);
	$ppr = Authen::Passphrase::DESCrypt
			->new(salt_base64 => $salt, hash_base64 => $hash);
	ok $ppr;
	ok !$ppr->fold;
	is $ppr->initial_base64, "...........";
	is $ppr->nrounds, 25;
	is $ppr->salt_base64_2, $salt;
	is $ppr->hash_base64, $hash;
	eval { $ppr->passphrase };
	isnt $@, "";
	is $ppr->as_crypt, $salt.$hash;
	is $ppr->as_rfc2307, "{CRYPT}".$salt.$hash;
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
Lg 3RoTEkqxIwA
f4 eGuaKa2lifE 0
Bu fiOozjn356. 1
e5 dUyXVDnKUOg foo
pl I4lcqu8wIO. supercalifragilisticexpialidocious
