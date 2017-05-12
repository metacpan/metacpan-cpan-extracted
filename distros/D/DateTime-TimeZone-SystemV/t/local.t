use warnings;
use strict;

use Test::More tests => 101;

{
	package FakeLocalDateTime;
	use Date::ISO8601 0.000 qw(ymd_to_cjdn);
	my $rdn_epoch_cjdn = 1721425;
	sub new {
		my($class, $y, $mo, $d, $h, $mi, $s) = @_;
		return bless({
			rdn => ymd_to_cjdn($y, $mo, $d) - $rdn_epoch_cjdn,
			sod => 3600*$h + 60*$mi + $s,
		}, $class);
	}
	sub local_rd_values { ($_[0]->{rdn}, $_[0]->{sod}, 0) }
}

require_ok "DateTime::TimeZone::SystemV";

my $tz;

sub try($$) {
	my($timespec, $offset) = @_;
	$timespec =~ /\A([0-9]{4})-([0-9]{2})-([0-9]{2})T
			([0-9]{2}):([0-9]{2}):([0-9]{2})\z/x or die;
	my $dt = FakeLocalDateTime->new("$1", "$2", "$3", "$4", "$5", "$6");
	is eval { $tz->offset_for_local_datetime($dt) }, $offset;
	unless(defined $offset) {
		like $@, qr/\A
			local\ time\ \Q$timespec\E\ does\ not\ exist
			\ in\ the\ [!-~]+\ timezone\ due\ to\ offset\ change
		\b/x;
	}
}

# constant offset
$tz = DateTime::TimeZone::SystemV->new("EST5");
try "2004-12-31T19:00:00", -18000;
try "2005-03-03T01:00:00", -18000;
try "2005-06-07T04:01:10", -18000;
try "2005-09-20T07:00:00", -18000;
try "2005-11-02T15:00:00", -18000;
try "2005-12-31T18:59:59", -18000;

# default DST rules, and inverted version of default DST rules
foreach("EST5EDT", "EDT4EST5,M10.5.0,M4.5.0") {
	$tz = DateTime::TimeZone::SystemV->new($_);
	try "2004-12-31T19:00:00", -18000;
	try "2005-03-03T01:00:00", -18000;
	try "2005-04-23T23:00:00", -18000;
	try "2005-04-23T23:59:59", -18000;
	try "2005-04-24T00:00:00", -18000;
	try "2005-04-24T00:59:59", -18000;
	try "2005-04-24T01:00:00", -18000;
	try "2005-04-24T01:59:59", -18000;
	try "2005-04-24T02:00:00", undef;
	try "2005-04-24T02:59:59", undef;
	try "2005-04-24T03:00:00", -14400;
	try "2005-04-24T03:59:59", -14400;
	try "2005-04-24T04:00:00", -14400;
	try "2005-04-24T04:59:59", -14400;
	try "2005-04-24T05:00:00", -14400;
	try "2005-04-24T05:59:59", -14400;
	try "2005-04-24T19:59:59", -14400;
	try "2005-04-24T20:00:00", -14400;
	try "2005-04-24T23:59:59", -14400;
	try "2005-04-25T00:00:00", -14400;
	try "2005-04-25T00:59:59", -14400;
	try "2005-04-25T01:00:00", -14400;
	try "2005-06-07T05:01:10", -14400;
	try "2005-09-20T08:00:00", -14400;
	try "2005-10-30T00:00:00", -14400;
	try "2005-10-30T00:59:59", -14400;
	try "2005-10-30T01:00:00", -18000;
	try "2005-10-30T01:59:59", -18000;
	try "2005-10-30T02:00:00", -18000;
	try "2005-10-30T02:59:59", -18000;
	try "2005-10-30T03:00:00", -18000;
	try "2005-10-30T03:59:59", -18000;
	try "2005-10-30T04:00:00", -18000;
	try "2005-10-30T04:59:59", -18000;
	try "2005-10-30T18:59:59", -18000;
	try "2005-10-30T19:00:00", -18000;
	try "2005-10-30T22:59:59", -18000;
	try "2005-10-30T23:00:00", -18000;
	try "2005-10-30T23:59:59", -18000;
	try "2005-10-31T00:00:00", -18000;
	try "2005-11-02T15:00:00", -18000;
	try "2005-12-31T18:59:59", -18000;
	try "2004-12-31T19:00:00", -18000;
}

# perpetual DST
$tz = DateTime::TimeZone::SystemV->new(system => "tzfile3",
	recipe => "AAA-2BBB,J1/0,J365/25");
try "2005-01-01T00:00:00", +10800;
try "2005-04-01T00:00:00", +10800;
try "2005-08-01T00:00:00", +10800;
try "2005-12-01T00:00:00", +10800;

1;
