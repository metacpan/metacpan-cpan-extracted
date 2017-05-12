use strict;
use Test;
BEGIN { plan tests => 18 }

use Convert::RACE qw(to_race from_race);

my(@utf16, @race);

push @utf16, "\x01\x2D\x01\x11\x01\x4B";
push @utf16, "\x01\x2D\x00\xe0\x01\x4B";
push @utf16, "\x01\x2D\x00\x20\x24\xd3";
push @utf16, "\x00\x64\x01\x7e\x01\xff";
# Test \x0A as low byte with \x00 as high byte
push @utf16, "\x00\x41\x00\x0A\x00\x62"; # "A\nb"
# Test \x0A as low byte with something als as high byte
push @utf16, "\x04\x22\x04\x10\x04\x0A\x04\x10"; # "TANYA" in Serbian
# Test \x0A as high byte
push @utf16, "\x0A\x2F\x0A\x41\x0A\x28\x0A\x3F"; # Gurmukhi "yuni"?
# Test \x0A as both high and low byte
push @utf16, "\x0A\x15\x0A\x0A\x0A\x24"; # Gurmukhi "kauuta"?
# Test 2 non-zero rows
push @utf16, "\x4E\x00\x75\x6A\x4E\x0A\x4E\xBA\x75\x1F"; # "ichiban ue jinsei"

push @race, 'bq--aewrcsy';
push @race, 'bq--aew77ycl';
push @race, 'bq--3aas2abaetjq';
push @race, 'bq--ah7wi7x7te';
push @race, 'bq--abaquyq';
push @race, 'bq--aqrbacqq';
push @race, 'bq--bixuckb7';
push @race, 'bq--bikquja';
push @race, 'bq--3bhaa5lkjyfe5otvd4';

for my $i (0..$#utf16) {
    ok(to_race($utf16[$i]), $race[$i]);
    ok(from_race($race[$i]), $utf16[$i]);
}
