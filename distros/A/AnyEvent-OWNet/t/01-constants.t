#!/usr/bin/perl
#
# Copyright (C) 2011 by Mark Hindess

use strict;
use constant { DEBUG => $ENV{ANYEVENT_OWNET_TEST_DEBUG} };
use Test::More tests => 17;
BEGIN {
  use_ok('AnyEvent::OWNet::Constants');
}

is(ownet_temperature_units(OWNET_CENTIGRADE), 'C', 'temp C');
is(ownet_temperature_units(OWNET_FAHRENHEIT), 'F', 'temp F');
is(ownet_temperature_units(OWNET_KELVIN), 'K', 'temp K');
is(ownet_temperature_units(OWNET_RANKINE), 'R', 'temp R');

is(ownet_pressure_units(OWNET_MILLIBAR), 'mbar', 'pressure mbar');
is(ownet_pressure_units(OWNET_ATMOSPHERE), 'atm', 'pressure atm');
is(ownet_pressure_units(OWNET_MM_MERCURY), 'mmHg', 'pressure mmHg');
is(ownet_pressure_units(OWNET_IN_MERCURY), 'inHg', 'pressure inHg');
is(ownet_pressure_units(OWNET_PSI), 'psi', 'pressure psi');
is(ownet_pressure_units(OWNET_PASCAL), 'Pa', 'pressure Pa');

is(ownet_display_format(OWNET_DISP_F_I), 'f.i', 'format f.i');
is(ownet_display_format(OWNET_DISP_FI), 'fi', 'format fi');
is(ownet_display_format(OWNET_DISP_F_I_C), 'f.i.c', 'format f.i.c');
is(ownet_display_format(OWNET_DISP_F_IC), 'f.ic', 'format f.ic');
is(ownet_display_format(OWNET_DISP_FI_C), 'fi.c', 'format fi.c');
is(ownet_display_format(OWNET_DISP_FIC), 'fic', 'format fic');
