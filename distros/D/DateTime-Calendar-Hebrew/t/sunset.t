use DateTime::Calendar::Hebrew;
use DateTime::Event::Sunrise;
print "1..1\n";

my $sunset = DateTime::Event::Sunrise->sunset (
	# Latitude/Longitude for NYC
	longitude =>'-73.59',
	latitude =>'40.38',
);

# Rosh HaShana (Jewish New Year) 2003/5764
$HT = new DateTime::Calendar::Hebrew(
	year   => 5764,
	month  => 7,
	day    => 1,
	hour   => 22,
	minute => 30,
	sunset => $sunset,
	time_zone => "America/New_York",
);

if($HT->{after_sunset} == 1) { print "ok\n"; }
else { print "not ok\n"; }

exit;
