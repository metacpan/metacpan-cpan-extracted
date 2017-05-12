use warnings;
use strict;

use Test::More tests => 14;

BEGIN { use_ok "Authen::Passphrase::RejectAll"; }

my $ppr = Authen::Passphrase::RejectAll->new;
ok $ppr;

my $ppr1 = Authen::Passphrase::RejectAll->from_crypt("*");
is $ppr1, $ppr;

eval { Authen::Passphrase::RejectAll->from_crypt("............."); };
isnt $@, "";

$ppr1 = Authen::Passphrase::RejectAll->from_rfc2307("{CrYpT}*");
is $ppr1, $ppr;

eval { Authen::Passphrase::RejectAll->from_rfc2307("{CrYpT}............."); };
isnt $@, "";

foreach my $passphrase("", qw(0 1 foo supercalifragilisticexpialidocious)) {
	ok !$ppr->match($passphrase);
}

eval { $ppr->passphrase };
isnt $@, "";

is $ppr->as_crypt, "*";
is $ppr->as_rfc2307, "{CRYPT}*";

1;
