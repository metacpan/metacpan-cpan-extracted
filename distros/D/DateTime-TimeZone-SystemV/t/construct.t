use warnings;
use strict;

use Test::More tests => 36;

require_ok "DateTime::TimeZone::SystemV";

my $tz;

$tz = DateTime::TimeZone::SystemV->new("EST5EDT");
ok $tz;
is $tz->name, "EST5EDT";

$tz = DateTime::TimeZone::SystemV->new(recipe => "EST5EDT");
ok $tz;
is $tz->name, "EST5EDT";

$tz = DateTime::TimeZone::SystemV->new(recipe => "EST5EDT", name => "foobar");
ok $tz;
is $tz->name, "foobar";

$tz = DateTime::TimeZone::SystemV->new(name => "foobar", recipe => "EST5EDT");
ok $tz;
is $tz->name, "foobar";

eval { DateTime::TimeZone::SystemV->new(); };
like $@, qr/\Arecipe not specified\b/;

eval { DateTime::TimeZone::SystemV->new(name => "foobar"); };
like $@, qr/\Arecipe not specified\b/;

eval { DateTime::TimeZone::SystemV->new(quux => "foobar"); };
like $@, qr/\Aunrecognised attribute\b/;

eval { DateTime::TimeZone::SystemV->new(name => "foobar", name => "quux"); };
like $@, qr/\Atimezone name specified redundantly\b/;

eval {
	DateTime::TimeZone::SystemV->new(recipe => "EST5EDT",
		recipe => "EST5EDT");
};
like $@, qr/\Arecipe specified redundantly\b/;

eval {
	DateTime::TimeZone::SystemV->new(system => "posix", system => "posix");
};
like $@, qr/\Asystem identifier specified redundantly\b/;

foreach(
	undef,
	[],
	*STDOUT,
	bless({}),
) {
	eval { DateTime::TimeZone::SystemV->new(name => $_) };
	like $@, qr/\Atimezone name must be a string\b/;
	eval { DateTime::TimeZone::SystemV->new(recipe => $_) };
	like $@, qr/\Arecipe must be a string\b/;
	eval { DateTime::TimeZone::SystemV->new(system => $_) };
	like $@, qr/\Asystem identifier must be a string\b/;
}

eval { DateTime::TimeZone::SystemV->new(system => "foobar"); };
like $@, qr/\Asystem identifier not recognised\b/;

eval { DateTime::TimeZone::SystemV->new(recipe => "EST"); };
like $@, qr/\Anot a valid SysV-style timezone recipe\b/;

eval { DateTime::TimeZone::SystemV->new(recipe => "EST", system => "posix"); };
like $@, qr/\Anot a valid SysV-style timezone recipe\b/;

eval {
	DateTime::TimeZone::SystemV->new(recipe => "EST", system => "tzfile3");
};
like $@, qr/\Anot a valid SysV-style timezone recipe\b/;

eval {
	DateTime::TimeZone::SystemV->new(recipe => "EST5EDT",
		system => "posix");
};
is $@, "";

eval {
	DateTime::TimeZone::SystemV->new(recipe => "EST5EDT",
		system => "tzfile3");
};
is $@, "";

eval {
	DateTime::TimeZone::SystemV->new(
		recipe => "EET-2EEST,M3.5.4/24,M9.3.6/145");
};
like $@, qr/\Anot a valid SysV-style timezone recipe\b/;

eval {
	DateTime::TimeZone::SystemV->new(
		recipe => "EET-2EEST,M3.5.4/24,M9.3.6/145",
		system => "posix");
};
like $@, qr/\Anot a valid SysV-style timezone recipe\b/;

eval {
	DateTime::TimeZone::SystemV->new(
		recipe => "EET-2EEST,M3.5.4/24,M9.3.6/145",
		system => "tzfile3");
};
is $@, "";

1;
