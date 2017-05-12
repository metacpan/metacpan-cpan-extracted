use warnings;
use strict;

use Test::More tests => 14;

BEGIN { use_ok "Authen::Passphrase::AcceptAll"; }

my $ppr = Authen::Passphrase::AcceptAll->new;
ok $ppr;

my $ppr1 = Authen::Passphrase::AcceptAll->from_crypt("");
is $ppr1, $ppr;

eval { Authen::Passphrase::AcceptAll->from_crypt("............."); };
isnt $@, "";

$ppr1 = Authen::Passphrase::AcceptAll->from_rfc2307("{CrYpT}");
is $ppr1, $ppr;

eval { Authen::Passphrase::AcceptAll->from_rfc2307("{CrYpT}............."); };
isnt $@, "";

foreach my $passphrase("", qw(0 1 foo supercalifragilisticexpialidocious)) {
	ok $ppr->match($passphrase);
}

is $ppr->passphrase, "";

is $ppr->as_crypt, "";
is $ppr->as_rfc2307, "{CRYPT}";

1;
