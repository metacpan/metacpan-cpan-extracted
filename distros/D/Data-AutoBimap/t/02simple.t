
use Test::More tests => 5;

use Data::AutoBimap;
my $bm = Data::AutoBimap->new;
is($bm->s2n("Test"), 1);
is($bm->s2n("123"), 2);
is($bm->s2n("Test"), 1);
is($bm->n2s(1), "Test");
ok(not defined $bm->n2s(3));

