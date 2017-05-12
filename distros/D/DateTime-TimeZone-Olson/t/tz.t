use warnings;
use strict;

use Test::More tests => 1 + 3 + 7*5;

BEGIN { use_ok "DateTime::TimeZone::Olson", qw(olson_tz); }

foreach(qw(
	America/Does_Not_Exist
	Does_Not_Exist/New_York
	Does_Not_Exist
)) {
	eval { olson_tz($_) };
	like $@, qr/\Ano such timezone/;
}

my $tz;

$tz = olson_tz("America/New_York");
ok $tz;
ok !$tz->is_floating;
ok !$tz->is_utc;
ok $tz->is_olson;
is $tz->category, "America";
is $tz->name, "America/New_York";
ok $tz->has_dst_changes;

$tz = olson_tz("US/Eastern");
ok $tz;
ok !$tz->is_floating;
ok !$tz->is_utc;
ok $tz->is_olson;
is $tz->category, "US";
is $tz->name, "US/Eastern";
ok $tz->has_dst_changes;

$tz = olson_tz("America/Indiana/Indianapolis");
ok $tz;
ok !$tz->is_floating;
ok !$tz->is_utc;
ok $tz->is_olson;
is $tz->category, "America";
is $tz->name, "America/Indiana/Indianapolis";
ok $tz->has_dst_changes;

$tz = olson_tz("UTC");
ok $tz;
ok !$tz->is_floating;
ok !$tz->is_utc;
ok $tz->is_olson;
is $tz->category, undef;
is $tz->name, "UTC";
ok !$tz->has_dst_changes;

$tz = olson_tz("Factory");
ok $tz;
ok !$tz->is_floating;
ok !$tz->is_utc;
ok $tz->is_olson;
is $tz->category, undef;
is $tz->name, "Factory";
ok !$tz->has_dst_changes;

1;
