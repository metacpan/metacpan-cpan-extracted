use warnings;
use strict;

use Test::More tests => 15;

require_ok "DateTime::TimeZone::SystemV";

my $tz;

$tz = DateTime::TimeZone::SystemV->new("EST5");
ok $tz;
ok !$tz->is_floating;
ok !$tz->is_utc;
ok !$tz->is_olson;
is $tz->category, undef;
is $tz->name, "EST5";
ok !$tz->has_dst_changes;

$tz = DateTime::TimeZone::SystemV->new(name => "foo", recipe => "EST5EDT");
ok $tz;
ok !$tz->is_floating;
ok !$tz->is_utc;
ok !$tz->is_olson;
is $tz->category, undef;
is $tz->name, "foo";
ok $tz->has_dst_changes;

1;
