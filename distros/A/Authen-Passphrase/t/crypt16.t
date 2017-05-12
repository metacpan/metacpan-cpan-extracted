use warnings;
use strict;

use Test::More tests => 83;

BEGIN { use_ok "Authen::Passphrase::Crypt16"; }

my $ppr = Authen::Passphrase::Crypt16
		->new(salt => 1234, hash => "abcdefghABCDEFGH");
ok $ppr;
is $ppr->salt, 1234;
is $ppr->salt_base64_2, "GH";
is $ppr->hash, "abcdefghABCDEFGH";
is $ppr->hash_base64, "MK7XN4JaNqUEI71F2J4FoU";
my $h0 = $ppr->first_half;
ok $h0;
is $h0->fold, !!0;
is $h0->initial, "\0\0\0\0\0\0\0\0";
is $h0->nrounds, 20;
is $h0->salt, 1234;
is $h0->hash_base64, "MK7XN4JaNqU";
my $h1 = $ppr->second_half;
ok $h1;
is $h1->fold, !!0;
is $h1->initial, "\0\0\0\0\0\0\0\0";
is $h1->nrounds, 5;
is $h1->salt, 1234;
is $h1->hash_base64, "EI71F2J4FoU";

$ppr = Authen::Passphrase::Crypt16
		->new(salt => 1234, passphrase => "wibble");
ok $ppr;
is $ppr->salt, 1234;
is $ppr->hash_base64, "QYUQgj6nmd.g/xAujudtXo";

$ppr = Authen::Passphrase::Crypt16
		->new(salt => 1234, passphrase => "wibblewobble");
ok $ppr;
is $ppr->salt, 1234;
is $ppr->hash_base64, "1ndJ4WMAo3s.CbKCSyRbco";

$ppr = Authen::Passphrase::Crypt16
		->new(salt_random => 12, passphrase => "wibblewobble");
ok $ppr;
is length($ppr->salt_base64_2), 2;
is length($ppr->hash), 16;
ok $ppr->match("wibblewobble");

my %pprs;
while(<DATA>) {
	chomp;
	s/([^ \n]+) ([^ \n]+) *//;
	my($salt, $hash) = ($1, $2);
	$ppr = Authen::Passphrase::Crypt16
			->new(salt_base64 => $salt, hash_base64 => $hash);
	ok $ppr;
	is $ppr->salt_base64_2, $salt;
	is $ppr->hash_base64, $hash;
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
7S ...........4VBRyAvp9nw
Ur ImG9Kp15IQsO2OoWANp2qc 0
QZ 7Dztte564Tsv/MSAT.EjMA 1
Qe tZVtOlWcUdEgK.3Asz6yo. foo
Uk uSoh3oV2exsgb27c/7adao supercalifragilisticexpialidocious
