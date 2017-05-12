use warnings;
use strict;

use Test::More tests => 100;

BEGIN { use_ok "Authen::Passphrase::PHPass"; }

my $ppr = Authen::Passphrase::PHPass
		->new(nrounds_log2 => 8,
		      salt => "V7qMYJaN",
		      hash => "ABCDEFGHIJKLMNOP");
ok $ppr;
is $ppr->cost, 8;
is $ppr->cost_base64, "6";
is $ppr->nrounds_log2, 8;
is $ppr->nrounds_log2_base64, "6";
is $ppr->salt, "V7qMYJaN";
is $ppr->hash, "ABCDEFGHIJKLMNOP";
is $ppr->hash_base64, "/7oE2JYF5VIG8h2HBtoHE/";

$ppr = Authen::Passphrase::PHPass
		->new(cost => 8,
		      salt => "V7qMYJaN",
		      hash_base64 => "/7oE2JYF5VIG8h2HBtoHE/");
ok $ppr;
is $ppr->cost, 8;
is $ppr->cost_base64, "6";
is $ppr->nrounds_log2, 8;
is $ppr->nrounds_log2_base64, "6";
is $ppr->salt, "V7qMYJaN";
is $ppr->hash, "ABCDEFGHIJKLMNOP";
is $ppr->hash_base64, "/7oE2JYF5VIG8h2HBtoHE/";

$ppr = Authen::Passphrase::PHPass
		->new(cost_base64 => "6",
		      salt => "V7qMYJaN",
		      passphrase => "wibble");
ok $ppr;
is $ppr->cost, 8;
is $ppr->cost_base64, "6";
is $ppr->nrounds_log2, 8;
is $ppr->nrounds_log2_base64, "6";
is $ppr->salt, "V7qMYJaN";
is $ppr->hash_base64, "DLIv8lDL.KgHUVyVKxhSH.";

$ppr = Authen::Passphrase::PHPass
		->new(nrounds_log2_base64 => "6", salt_random => 1,
		      passphrase => "wibble");
ok $ppr;
is $ppr->cost, 8;
is $ppr->cost_base64, "6";
is $ppr->nrounds_log2, 8;
is $ppr->nrounds_log2_base64, "6";
like $ppr->salt, qr#\A[./0-9A-Za-z]{8}\z#;
is length($ppr->hash), 16;
ok $ppr->match("wibble");

$ppr = Authen::Passphrase::PHPass
	->from_crypt('$P$8NaClNaClMeOtoCi6dkB5NlSyY.wFQ.');
ok $ppr;
is $ppr->cost, 10;
is $ppr->salt, "NaClNaCl";
is $ppr->hash_base64, "MeOtoCi6dkB5NlSyY.wFQ.";

$ppr = Authen::Passphrase::PHPass
	->from_rfc2307('{CrYpT}$P$8NaClNaClMeOtoCi6dkB5NlSyY.wFQ.');
ok $ppr;
is $ppr->cost, 10;
is $ppr->salt, "NaClNaCl";
is $ppr->hash_base64, "MeOtoCi6dkB5NlSyY.wFQ.";

my %pprs;
while(<DATA>) {
	chomp;
	s/([^ \n]+) ([^ \n]+) ([^ \n]+) *//;
	my($cost_base64, $salt, $hash_base64) = ($1, $2, $3, $4);
	$ppr = Authen::Passphrase::PHPass
			->new(cost_base64 => $cost_base64,
			      salt => $salt,
			      hash_base64 => $hash_base64);
	ok $ppr;
	is $ppr->cost_base64, $cost_base64;
	is $ppr->salt, $salt;
	is $ppr->hash_base64, $hash_base64;
	eval { $ppr->passphrase }; isnt $@, "";
	my $crypt_string = "\$P\$".$cost_base64.$salt.$hash_base64;
	is $ppr->as_crypt, $crypt_string;
	is $ppr->as_rfc2307, "{CRYPT}$crypt_string";
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
6 MVeiwNN2 Z9ajy4aaEmIhSGxgfIMbF/
3 tWgAqczl uHKlOhHYT1V80gVQxgypw. 0
7 Fi0425wg bQvE6tzjOfMPGgENlndLm/ 1
8 EP62lbrh mf/uFiTNicupnEEbqAbK70 foo
9 /.ksQxvw hZ7Sdy4MmLyS15OJjhbrG1 supercalifragilisticexpialidocious
