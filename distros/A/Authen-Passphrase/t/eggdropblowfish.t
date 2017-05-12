use warnings;
use strict;

use Test::More tests => 84;

BEGIN { use_ok "Authen::Passphrase::EggdropBlowfish"; }

my $ppr = Authen::Passphrase::EggdropBlowfish->new(passphrase => "wibble");
ok $ppr;
is $ppr->hash, "\xdc\x05\x56\x67\x87\x9a\xac\xe1";
is $ppr->hash_base64, "vNEA50Bnj/q1";
ok $ppr->match("wibble");

$ppr = Authen::Passphrase::EggdropBlowfish->new(
	hash => "\xdc\x05\x56\x67\x87\x9a\xac\xe1");
ok $ppr;
is $ppr->hash, "\xdc\x05\x56\x67\x87\x9a\xac\xe1";
is $ppr->hash_base64, "vNEA50Bnj/q1";

$ppr = Authen::Passphrase::EggdropBlowfish->new(hash_base64 => "vNEA50Bnj/q1");
ok $ppr;
is $ppr->hash, "\xdc\x05\x56\x67\x87\x9a\xac\xe1";
is $ppr->hash_base64, "vNEA50Bnj/q1";

eval { Authen::Passphrase::EggdropBlowfish->new(passphrase => ""); };
isnt $@, "";

my %pprs;
my $i = 0;
while(<DATA>) {
	chomp;
	s/([^ \n]+) *//;
	my $hash_base64 = $1;
	$ppr = Authen::Passphrase::EggdropBlowfish
		->new(hash_base64 => $hash_base64);
	ok $ppr;
	is $ppr->hash_base64, $hash_base64;
	eval { $ppr->passphrase }; isnt $@, "";
	eval { $ppr->as_crypt }; isnt $@, "";
	eval { $ppr->as_rfc2307 }; isnt $@, "";
	$pprs{$_} = $ppr;
}

foreach my $rightphrase (sort keys %pprs) {
	my $ppr = $pprs{$rightphrase};
	ok !$ppr->match("");
	foreach my $passphrase (sort keys %pprs) {
		ok ($ppr->match($passphrase) xor $passphrase ne $rightphrase);
	}
}

1;

__DATA__
v.gq8.qm3rM1 0
V6ZOx0rVGWT0 1
AINZW/4MSzQ1 foo
V7/Cv0ShonY0 supercalifragilisticexpialidocious
jdwmI1F5evD0 abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqr
UlrmE/pDCZE/ abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz
