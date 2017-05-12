use DateTime::Calendar::Hebrew;
use DateTime::Event::Sunrise;
print "1..1\n";

my $sunset = DateTime::Event::Sunrise->sunset (
    # Latitude/Longitude for NYC
	longitude =>'-73.59',
	latitude =>'40.38',
);

# the date the Ancient Israelites left Egypt
my $DT = new DateTime::Calendar::Hebrew(
	year => 2449,
	month => 1,
	day => 15,
	hour => 23,
	minute => 59,
	second => 0,
	nanosecond => 987654321,
	time_zone => 'America/New_York',
	sunset => $sunset,
);

my $clone = $DT->clone;
print Dumper $clone;
if($DT->utc_rd_as_seconds == $clone->utc_rd_as_seconds) { print "ok\n"; }
else { print "not ok\n"; }

exit;
