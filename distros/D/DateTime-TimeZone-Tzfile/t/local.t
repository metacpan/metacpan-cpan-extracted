use warnings;
use strict;

use Test::More tests => 113;

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

require_ok "DateTime::TimeZone::Tzfile";

my $tz;

sub try($$) {
	my($timespec, $offset) = @_;
	$timespec =~ /\A([0-9]{4})-([0-9]{2})-([0-9]{2})T
			([0-9]{2}):([0-9]{2}):([0-9]{2})\z/x or die;
	my $dt = FakeLocalDateTime->new("$1", "$2", "$3", "$4", "$5", "$6");
	my $errcond;
	unless($offset =~ /\A[-+]?[0-9]+\z/) {
		$errcond = $offset;
		$offset = undef;
	}
	is eval { $tz->offset_for_local_datetime($dt) }, $offset,
		"offset for $timespec";
	unless(defined $offset) {
		like $@, qr#\A
			local\ time\ \Q$timespec\E\ does\ not\ exist
			\ in\ the\ [!-~]+\ timezone\ due\ to\ \Q$errcond\E
		\b#x, "error message for $timespec";
	}
}

$tz = DateTime::TimeZone::Tzfile->new("t/London.tz");
try "1800-01-01T00:00:00", -75;
try "1920-03-28T01:59:59", +0;
try "1920-03-28T02:00:00", "offset change";
try "1920-03-28T02:59:59", "offset change";
try "1920-03-28T03:00:00", +3600;
try "1920-10-25T01:59:59", +3600;
try "1920-10-25T02:00:00", +0;
try "1920-10-25T02:59:59", +0;
try "1920-10-25T03:00:00", +0;
try "1942-04-05T01:59:59", +3600;
try "1942-04-05T02:00:00", "offset change";
try "1942-04-05T02:59:59", "offset change";
try "1942-04-05T03:00:00", +7200;
try "2039-03-27T00:59:59", +0;
try "2039-03-27T01:00:00", "offset change";
try "2039-03-27T01:59:59", "offset change";
try "2039-03-27T02:00:00", +3600;
try "2039-10-30T00:59:59", +3600;
try "2039-10-30T01:00:00", +0;
try "2039-10-30T01:59:59", +0;
try "2039-10-30T02:00:00", +0;

# The Davis base in Antarctica has been uninhabited at times.
$tz = DateTime::TimeZone::Tzfile->new("t/Davis.tz");
try "1953-07-01T12:00:00", "zone disuse";
try "1957-01-13T06:59:59", "zone disuse";
try "1957-01-13T07:00:00", +25200;
try "1960-01-01T12:00:00", +25200;
try "1964-10-31T23:59:59", +25200;
try "1964-11-01T00:00:00", "zone disuse";
try "1967-01-01T12:00:00", "zone disuse";
try "1969-02-01T06:59:59", "zone disuse";
try "1969-02-01T07:00:00", +25200;
try "1980-01-01T12:00:00", +25200;
try "2009-10-17T23:59:59", +25200;
try "2009-10-18T00:00:00", +18000;
try "2010-01-01T12:00:00", +18000;
try "2010-03-11T00:59:59", +18000;
try "2010-03-11T01:00:00", "offset change";
try "2010-03-11T02:59:59", "offset change";
try "2010-03-11T03:00:00", +25200;
try "2011-01-01T12:00:00", +25200;

# This version of San_Luis.tz has no POSIX-TZ extension rule, because
# the source data ends with an indefinite-future observance that is on
# DST, and that can't be expressed in a POSIX-TZ recipe.  The correct
# interpretation of the tzfile is that the zone behaviour is unknown
# after the final transition time.
$tz = DateTime::TimeZone::Tzfile->new("t/San_Luis.tz");
try "2008-01-01T12:00:00", -7200;
try "2008-01-20T22:59:59", -7200;
try "2008-01-20T23:00:00", -10800;
try "2008-02-01T12:00:00", -10800;
try "2008-03-08T22:59:59", -10800;
try "2008-03-08T23:00:00", -14400;
try "2008-06-01T12:00:00", -14400;
try "2008-10-11T23:59:59", -14400;
try "2008-10-12T00:00:00", "offset change";
try "2008-10-12T00:59:59", "offset change";
try "2008-10-12T01:00:00", -10800;
try "2009-01-01T12:00:00", -10800;
try "2009-03-07T22:59:59", -10800;
try "2009-03-07T23:00:00", -14400;
try "2009-06-01T12:00:00", -14400;
try "2009-10-10T23:59:59", -14400;
try "2009-10-11T00:00:00", "missing data";
try "2010-01-01T12:00:00", "missing data";

# Loyston was settled in the early 19th century and ultimately abandoned
# in 1936 to make way for the Norris Lake.  This tzfile is not from the
# Olson database.  It's here to test the handling of a presently-disused
# zone.
$tz = DateTime::TimeZone::Tzfile->new("t/Loyston.tz");
try "1799-01-01T12:00:00", "zone disuse";
try "1799-12-31T18:24:15", "zone disuse";
try "1799-12-31T18:24:16", -20144;
try "1840-01-01T12:00:00", -20144;
try "1883-11-18T11:24:15", -20144;
try "1883-11-18T11:24:16", "offset change";
try "1883-11-18T11:59:59", "offset change";
try "1883-11-18T12:00:00", -18000;
try "1900-01-01T12:00:00", -18000;
try "1918-03-31T01:59:59", -18000;
try "1918-03-31T02:00:00", "offset change";
try "1918-03-31T02:59:59", "offset change";
try "1918-03-31T03:00:00", -14400;
try "1918-07-01T12:00:00", -14400;
try "1918-10-27T00:59:59", -14400;
try "1918-10-27T01:00:00", -18000;
try "1919-01-01T12:00:00", -18000;
try "1919-03-30T01:59:59", -18000;
try "1919-03-30T02:00:00", "offset change";
try "1919-03-30T02:59:59", "offset change";
try "1919-03-30T03:00:00", -14400;
try "1919-07-01T12:00:00", -14400;
try "1919-10-26T00:59:59", -14400;
try "1919-10-26T01:00:00", -18000;
try "1930-01-01T12:00:00", -18000;
try "1936-03-03T23:59:59", -18000;
try "1936-03-04T00:00:00", "zone disuse";
try "1937-01-01T12:00:00", "zone disuse";

1;
