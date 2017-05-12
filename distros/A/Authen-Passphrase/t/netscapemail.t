use warnings;
use strict;

use Test::More tests => 67;

BEGIN { use_ok "Authen::Passphrase::NetscapeMail"; }

my $ppr = Authen::Passphrase::NetscapeMail
		->new(salt => "abcdefghijklmnopABCDEFGHIJKLMNOP",
		      passphrase => "wibble");
ok $ppr;
is $ppr->salt, "abcdefghijklmnopABCDEFGHIJKLMNOP";
is $ppr->hash, "\x6f\xc4\xc7\x45\xd9\x6d\x05\x53".
		"\xd8\x95\x39\x33\x81\x75\x38\xfe";
is $ppr->hash_hex, "6fc4c745d96d0553d8953933817538fe";

$ppr = Authen::Passphrase::NetscapeMail
		->new(salt_random => 1,
		      passphrase => "wibble");
ok $ppr;
like $ppr->salt, qr/\A[0-9a-f]{32}\z/;
is length($ppr->hash), 16;
ok $ppr->match("wibble");

$ppr = Authen::Passphrase::NetscapeMail->from_rfc2307(
	"{NS-MTA-MD5}f553c0b7d40a9f815638FCAC319e30c2".
	"45f6204ab8e103b3dc38a93fbf4d1ad1");
ok $ppr;
is $ppr->salt, "45f6204ab8e103b3dc38a93fbf4d1ad1";
is $ppr->hash_hex, "f553c0b7d40a9f815638fcac319e30c2";

my %pprs;
my $i = 0;
while(<DATA>) {
	chomp;
	s/([^ \n]+) ([^ \n]+) *//;
	my($salt, $hash_hex) = ($1, $2);
	$ppr = Authen::Passphrase::NetscapeMail
			->new(salt => $salt,
			      ($i++ & 1) ? (hash_hex => $hash_hex) :
					   (hash => pack("H*", $hash_hex)));
	ok $ppr;
	is $ppr->salt, $salt;
	is $ppr->hash_hex, lc($hash_hex);
	is $ppr->hash, pack("H*", $hash_hex);
	eval { $ppr->passphrase }; isnt $@, "";
	is $ppr->as_rfc2307, "{NS-MTA-MD5}".lc($hash_hex).$salt;
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
hlV8:`2Q4?@^If)5(cf4xbDKV#o\Sk(` d019c4507be8652975e62871acaa7b52
te6]{4LF|aKFZ;Gcd0}Mul"Wmfg\;fn) 8178663855a984e46d55c57beecefdc2 0
PmkK.8*qCB5JDq}]d#B]8/2`sGENeHKK 8129e982919eec1a70c0a7b28e8425c3 1
m6x*g?v;,"\i[|7/rto~Su6rH?*t|L50 585C16EFA23F1FB1259318314DD78D57 foo
<#O[v2gbw46=L}frBIgJ1l:Hw3Z9Wz[, f168cf3e2e5558c2b1be5841d3601e10 supercalifragilisticexpialidocious
