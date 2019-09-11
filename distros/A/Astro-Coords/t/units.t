#!perl

use strict;
use Test::More tests => 1 + 6 + 12 + 8;
use Test::Number::Delta within => 1e-9;

use Astro::Telescope;

require_ok('Astro::Coords');

my ($c, $az, $el, $ha, $dec);
my $tel = new Astro::Telescope('UKIRT');

# Equatorial coordinates.
$c = new Astro::Coords(
    ra => '12:34:56', dec => '7:08:09',
    type => 'J2000', units => 'sexagesimal');

delta_ok($c->ra()->hours(), 12.582222222222223, 'eq sexagesimal ra');
delta_ok($c->dec()->degrees(), 7.135833333333333, 'eq sexagesimal dec');

$c = new Astro::Coords(
    ra => '123.456', dec => '76.543',
    type => 'J2000', units => 'degrees');

delta_ok($c->ra()->degrees(), 123.456, 'eq deg ra');
delta_ok($c->dec()->degrees(), 76.543, 'eq deg dec');

$c = new Astro::Coords(
    ra => '12.3456', dec => '65.432',
    type => 'J2000', units => ['hours', 'degrees']);

delta_ok($c->ra()->hours(), 12.3456, 'eq hour,deg ra');
delta_ok($c->dec()->degrees(), 65.432, 'eq hour,deg dec');

# Fixed coordinates.
$c = new Astro::Coords(
    az => 120.0, el => 240.0,
    units => 'arcminutes');

($az, $el) = $c->azel();
delta_ok($az->degrees(), 2.0, 'azel am az');
delta_ok($el->degrees(), 4.0, 'azel am el');

$c = new Astro::Coords(
    az => 3600.0, el => 2.0,
    units => ['arcseconds', 'degrees']);

($az, $el) = $c->azel();
delta_ok($az->degrees(), 1.0, 'azel as,deg az');
delta_ok($el->degrees(), 2.0, 'azel as,deg el');

$c = new Astro::Coords(
    az => 2.0, el => 3600.0,
    units => ['degrees', 'arcseconds']);

($az, $el) = $c->azel();
delta_ok($az->degrees(), 2.0, 'azel deg,as az');
delta_ok($el->degrees(), 1.0, 'azel deg,as el');

$c = new Astro::Coords(
    ha => '1:34:56', dec => '45:00:00',
    units => 'sexagesimal', tel => $tel);

($ha, $dec) = $c->hadec();
delta_ok($ha->hours(), 1.582222222222223, 'hadec sexagesimal ha');
delta_ok($dec->degrees(), 45.0, 'hadec sexagesimal dec');

$c = new Astro::Coords(
    ha => 15.0, dec => 55.0,
    units => 'degrees', tel => $tel);

($ha, $dec) = $c->hadec();
delta_ok($ha->degrees(), 15.0, 'hadec degreees ha');
delta_ok($dec->degrees(), 55.0, 'hadec degrees dec');

$c = new Astro::Coords(
    ha => 1.50, dec => 35.0,
    units => ['hours', 'degrees'], tel => $tel);

($ha, $dec) = $c->hadec();
delta_ok($ha->hours(), 1.50, 'hadec hour,deg ha');
delta_ok($dec->degrees(), 35.0, 'hadec hour,deg dec');

# Interpolated coordinates.
$c = new Astro::Coords(
    ra1 => 1.23, dec1 => 4.56, mjd1 => 58000.0,
    ra2 => 2.34, dec2 => 5.67, mjd2 => 58100.0,
    units => 'degrees');

delta_ok($c->ra1(format => 'degrees'), 1.23, 'interp degrees ra1');
delta_ok($c->dec1(format => 'degrees'), 4.56, 'interp degrees dec1');
delta_ok($c->ra2(format => 'degrees'), 2.34, 'interp degrees ra2');
delta_ok($c->dec2(format => 'degrees'), 5.67, 'interp degrees dec2');

$c = new Astro::Coords(
    ra1 => 0.123, dec1 => -4.56, mjd1 => 58000.0,
    ra2 => 0.234, dec2 => -5.67, mjd2 => 58100.0,
    units => ['hours', 'degrees']);

delta_ok($c->ra1(format => 'hours'), 0.123, 'interp hour,deg ra1');
delta_ok($c->dec1(format => 'degrees'), -4.56, 'interp degrees dec1');
delta_ok($c->ra2(format => 'hours'), 0.234, 'interp hour,deg ra2');
delta_ok($c->dec2(format => 'degrees'), -5.67, 'interp degrees dec2');
