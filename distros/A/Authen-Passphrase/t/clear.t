use warnings;
use strict;

use Test::More tests => 49;

BEGIN { use_ok "Authen::Passphrase::Clear"; }

my $ppr = Authen::Passphrase::Clear->from_rfc2307("{CLEARTEXT}womble");
ok $ppr;
is $ppr->passphrase, "womble";
eval { Authen::Passphrase::Clear->from_rfc2307("{CRYPT}*"); };
isnt $@, "";

my @test_phrases = ("", qw(0 1 foo supercalifragilisticexpialidocious));

foreach my $rightphrase (@test_phrases) {
	$ppr = Authen::Passphrase::Clear->new($rightphrase);
	ok $ppr;
	foreach my $passphrase (@test_phrases) {
		ok ($ppr->match($passphrase) xor $passphrase ne $rightphrase);
	}
	is $ppr->passphrase, $rightphrase;
	eval { $ppr->as_crypt };
	isnt $@, "";
	is $ppr->as_rfc2307, "{CLEARTEXT}".$rightphrase;
}

1;
