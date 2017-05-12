use strict;
use warnings;
use Test::More tests => 17;
use Astro::Nova;

SCOPE: {
  pass();
  ok(Astro::Nova::get_apparent_sidereal_time(0) > 1., "apparent sidereal time is there");
  my $date = Astro::Nova::Date->new();
  isa_ok($date, "Astro::Nova::Date");
  is($date->get_years, 0);

  my $hequ_pos = Astro::Nova::HEquPosn->new();
  isa_ok($hequ_pos, "Astro::Nova::HEquPosn");
  my $hms = $hequ_pos->get_ra;
  isa_ok($hms, "Astro::Nova::HMS");
  is($hms->get_hours, 0);
  $hms->set_hours(2);
  is($hms->get_hours, 2);
  is($hequ_pos->get_ra->get_hours, 0);
  $hequ_pos->set_ra($hms);
  is($hequ_pos->get_ra->get_hours, 2);

  my $mean_pos = Astro::Nova::EquPosn->new();
  my $res = Astro::Nova::get_equ_aber($mean_pos, 0);
  isa_ok($res, 'Astro::Nova::EquPosn');
}

pass();

SCOPE: {
  my @res = Astro::Nova::get_earth_centre_dist(0., 0.);
  ok(@res == 2);
}

pass();

SCOPE: {
  my $orbit = Astro::Nova::EllOrbit->new();
  my $observer = Astro::Nova::LnLatPosn->new();
  my @res = Astro::Nova::get_ell_body_rst(0, $observer, $orbit);
  ok(@res == 2);
  isa_ok($res[1], 'Astro::Nova::RstTime');
}

pass();


