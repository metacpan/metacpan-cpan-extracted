use warnings;
use strict;

use Test::More tests => 176;

BEGIN { use_ok "Authen::Passphrase::BigCrypt"; }

my $ppr = Authen::Passphrase::BigCrypt
		->new(salt => 1234, hash => "abcdefghABCDEFGH");
ok $ppr;
is $ppr->salt, 1234;
is $ppr->salt_base64_2, "GH";
is $ppr->hash, "abcdefghABCDEFGH";
is $ppr->hash_base64, "MK7XN4JaNqUEI71F2J4FoU";
is scalar(@{$ppr->sections}), 2;
my($h0, $h1) = @{$ppr->sections};
ok $h0;
is $h0->fold, !!0;
is $h0->initial, "\0\0\0\0\0\0\0\0";
is $h0->nrounds, 25;
is $h0->salt, 1234;
is $h0->hash_base64, "MK7XN4JaNqU";
ok $h1;
is $h1->fold, !!0;
is $h1->initial, "\0\0\0\0\0\0\0\0";
is $h1->nrounds, 25;
is $h1->salt_base64_2, "MK";
is $h1->hash_base64, "EI71F2J4FoU";

$ppr = Authen::Passphrase::BigCrypt
		->new(salt => 1234, passphrase => "wibble");
ok $ppr;
is $ppr->salt, 1234;
is $ppr->hash_base64, "pWC.A0n3XaE";
is scalar(@{$ppr->sections}), 1;
is $ppr->sections->[0]->as_crypt, "GHpWC.A0n3XaE";

$ppr = Authen::Passphrase::BigCrypt
		->new(salt => 1234, passphrase => "wibblewobble");
ok $ppr;
is $ppr->salt, 1234;
is $ppr->hash_base64, "ClcTIo/hKYMIsgSBrBO7vU";
is scalar(@{$ppr->sections}), 2;
is $ppr->sections->[0]->as_crypt, "GHClcTIo/hKYM";
is $ppr->sections->[1]->as_crypt, "ClIsgSBrBO7vU";

$ppr = Authen::Passphrase::BigCrypt
		->new(salt => 1234, passphrase => "wibblewobblewubble");
ok $ppr;
is $ppr->salt, 1234;
is $ppr->hash_base64, "ClcTIo/hKYMRkDdXYPXjHE9gaQPFUyS3U";
is scalar(@{$ppr->sections}), 3;
is $ppr->sections->[0]->as_crypt, "GHClcTIo/hKYM";
is $ppr->sections->[1]->as_crypt, "ClRkDdXYPXjHE";
is $ppr->sections->[2]->as_crypt, "Rk9gaQPFUyS3U";

$ppr = Authen::Passphrase::BigCrypt
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
	$ppr = Authen::Passphrase::BigCrypt
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
7S 4VBRyAvp9nw
Ur 6e9cwNFemc. 0
QZ e2iVWSOxMVk 1
Qe KQ9Te3r2O4o foo
JG w9PEfARmc7A supercal
yU 7SM20XfzOvsZludTWFafCE supercalfoo
vY JR2.m1Ow1WYVoCn.TiPmZw 01234567foo
Cy kVuwUqTCr52CwqaDc8rfnE supercalifragili
Uk U3cGYFW4ueM72AolWB5yawnxRA.6JGrikjBe.CyUFGDUbf0RYcrvYyU supercalifragilisticexpialidocious
