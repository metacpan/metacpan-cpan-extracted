use strict;
use warnings;
use Test::More tests => 29+7;
use Astro::Nova;

my $zd = Astro::Nova::DMS->new();
isa_ok($zd, 'Astro::Nova::DMS');

is($zd->get_degrees, 0);
$zd->set_all();
is($zd->get_degrees, 0);
is(($zd->members)[1], 'degrees');
is(scalar($zd->get_all()), 4);
$zd->set_degrees(4);
is(($zd->get_all)[1], 4);
is($zd->get_degrees(), 4);
$zd->set_all(undef, 12, undef, 5);
is(($zd->get_all)[0], 0);
is(($zd->get_all)[1], 12);
is(($zd->get_all)[2], 0);
is(($zd->get_all)[3], 5);


$zd = Astro::Nova::DMS->new();
$zd->from_string("-5° 12' 1''");
is($zd->get_neg(), 1);
is($zd->get_degrees(), 5);
is($zd->get_minutes(), 12);
is($zd->get_seconds(), 1);

$zd->from_string("2° 10'");
is($zd->get_neg(), 0);
is($zd->get_degrees(), 2);
is($zd->get_minutes(), 10);
is($zd->get_seconds(), 0);

$zd = Astro::Nova::DMS->new(neg => 0, minutes => 1, seconds => 5, degrees => 12);
isa_ok($zd, 'Astro::Nova::DMS');
is($zd->get_neg(), 0);
is($zd->get_degrees(), 12);
is($zd->get_minutes(), 1);
is($zd->get_seconds(), 5);

my $hms = $zd->to_hms();
isa_ok($hms, 'Astro::Nova::HMS');
my $oldref = "$zd";
$zd = $hms->to_dms();
isa_ok($zd, 'Astro::Nova::DMS');
ok($oldref ne "$zd");
my $eps = 1.e-6;
ok($zd->get_neg()-$eps < 0 and $zd->get_neg()+$eps > 0);
ok($zd->get_degrees()-$eps < 12 and $zd->get_degrees()+$eps > 12);
ok($zd->get_minutes()-$eps < 1 and $zd->get_minutes()+$eps > 1);
ok($zd->get_seconds()-$eps < 5 and $zd->get_seconds()+$eps > 5);

$zd = Astro::Nova::DMS->new(blah => "blah");
isa_ok($zd, 'Astro::Nova::DMS');
is($zd->get_neg(), 0);
is($zd->get_degrees(), 0);
is($zd->get_minutes(), 0);
is($zd->get_seconds(), 0);


