use warnings;
use strict;

use Test::More tests => 103;

BEGIN { use_ok "Authen::Passphrase::BlowfishCrypt"; }

my $ppr = Authen::Passphrase::BlowfishCrypt
		->new(keying_nrounds_log2 => 8,
		      salt => "abcdefghijklmnop",
		      hash => "ABCDEFGHIJKLMNOPQRSTUVW");
ok $ppr;
ok $ppr->key_nul;
is $ppr->cost, 8;
is $ppr->keying_nrounds_log2, 8;
is $ppr->salt, "abcdefghijklmnop";
is $ppr->salt_base64, "WUHhXETkX0fnYkrqZU3ta.";
is $ppr->hash, "ABCDEFGHIJKLMNOPQRSTUVW";
is $ppr->hash_base64, "OSHBPCTEPyfHQirKRS3NSDDQSzPTTja";

$ppr = Authen::Passphrase::BlowfishCrypt
		->new(cost => 8,
		      salt_base64 => "WUHhXETkX0fnYkrqZU3ta.",
		      hash_base64 => "OSHBPCTEPyfHQirKRS3NSDDQSzPTTja");
ok $ppr;
ok $ppr->key_nul;
is $ppr->cost, 8;
is $ppr->keying_nrounds_log2, 8;
is $ppr->salt, "abcdefghijklmnop";
is $ppr->salt_base64, "WUHhXETkX0fnYkrqZU3ta.";
is $ppr->hash, "ABCDEFGHIJKLMNOPQRSTUVW";
is $ppr->hash_base64, "OSHBPCTEPyfHQirKRS3NSDDQSzPTTja";

$ppr = Authen::Passphrase::BlowfishCrypt
		->new(cost => 8,
		      salt_base64 => "WUHhXETkX0fnYkrqZU3ta.",
		      passphrase => "wibble");
ok $ppr;
ok $ppr->key_nul;
is $ppr->cost, 8;
is $ppr->salt_base64, "WUHhXETkX0fnYkrqZU3ta.";
is $ppr->hash_base64, "blPSuQlDs8xl6eM1xtMFFn1QKYeXCXO";

$ppr = Authen::Passphrase::BlowfishCrypt
		->new(cost => 8, salt_random => 1,
		      passphrase => "wibble");
ok $ppr;
ok $ppr->key_nul;
is $ppr->cost, 8;
is length($ppr->salt), 16;
is length($ppr->hash), 23;
ok $ppr->match("wibble");

$ppr = Authen::Passphrase::BlowfishCrypt
	->from_crypt('$2a$08$s5VYb9QzBzTUE3h66kH6hOQ'.
		     'JjrUXrZskQrnTq0SOwFkM0sRsvuzqC');
ok $ppr;
ok $ppr->key_nul;
is $ppr->cost, 8;
is $ppr->salt_base64, "s5VYb9QzBzTUE3h66kH6hO";
is $ppr->hash_base64, "QJjrUXrZskQrnTq0SOwFkM0sRsvuzqC";

$ppr = Authen::Passphrase::BlowfishCrypt
	->from_rfc2307('{CrYpT}$2a$08$s5VYb9QzBzTUE3h66kH6hOQ'.
		     'JjrUXrZskQrnTq0SOwFkM0sRsvuzqC');
ok $ppr;
ok $ppr->key_nul;
is $ppr->cost, 8;
is $ppr->salt_base64, "s5VYb9QzBzTUE3h66kH6hO";
is $ppr->hash_base64, "QJjrUXrZskQrnTq0SOwFkM0sRsvuzqC";

my %pprs;
while(<DATA>) {
	chomp;
	s/([^ \n]+) ([^ \n]+) ([^ \n]+) ([^ \n]+) *//;
	my($knul, $cost, $salt_base64, $hash_base64) = ($1, $2, $3, $4);
	$ppr = Authen::Passphrase::BlowfishCrypt
			->new(key_nul => $knul, cost => $cost,
			      salt_base64 => $salt_base64,
			      hash_base64 => $hash_base64);
	ok $ppr;
	is !!$ppr->key_nul, !!$knul;
	is $ppr->cost, $cost;
	is $ppr->salt_base64, $salt_base64;
	is $ppr->hash_base64, $hash_base64;
	eval { $ppr->passphrase }; isnt $@, "";
	my $crypt_string = "\$2".($knul ? "a" : "")."\$0".$cost."\$".
			   $salt_base64.$hash_base64;
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
0 6 Yn6x4nvPtEPkdmRQ74S1Q. ehVP/UL/xbYgKCilZtidy3nc5ttCeLa
0 6 EJv2xOCAoTkNo9y/BtUdLe OVbnD8L9oD7DVE7g0hJgCQO0YA7UHx2 0
0 8 b8i4onzFJ0egD/hxHXSl1O 1dSVPvRb6q5pY5kjW8sYnmfnMWAwPX2 1
1 9 jFan8v8EukXTQzWOHA3Hlu GrNPCCLl5347WLZCdCuNp2VKZOXEDYC foo
0 2 /5A.BZ8WXbFhIEZK5WP7Ku VOUYef56LKYc.4FNp0im8EX7X31EnOa supercalifragilisticexpialidocious
