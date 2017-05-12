use strict;
use warnings;
use Test::More tests => 12;
use Astro::Nova;

my $zd = Astro::Nova::ZoneDate->new();
isa_ok($zd, 'Astro::Nova::ZoneDate');

is($zd->get_years, 0);
$zd->set_all();
is($zd->get_years, 0);
is(($zd->members)[0], 'years');
is(scalar($zd->get_all()), 7);
$zd->set_years(4);
is(($zd->get_all)[0], 4);
is($zd->get_years(), 4);
$zd->set_all(undef, 12, undef, 5);
is(($zd->get_all)[0], 4);
is(($zd->get_all)[1], 12);
is(($zd->get_all)[2], 0);
is(($zd->get_all)[3], 5);
ok($zd->as_ascii()=~/Year:\s*4/);

