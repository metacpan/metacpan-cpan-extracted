#!/usr/local/bin/perl
use DateTime::Calendar::Hebrew;
use DateTime::Event::Sunrise;

my $sunset = DateTime::Event::Sunrise->sunset (
	# Latitude/Longitude for NYC
	longitude =>'-73.59',
	latitude =>'40.38',
);

$DT = new DateTime(
	year => 2003,
	month => 9,
	day => 26,
	hour   => 22,
	minute => 30,
);

$HT = DateTime::Calendar::Hebrew->from_object(object => $DT);
print $DT->datetime, " (RD", ($DT->utc_rd_values)[0], ") -> ", $HT->datetime, "\n";

$HT->set(
	sunset => $sunset,
	time_zone => "America/New_York",
);
print $DT->datetime, " (RD", ($DT->utc_rd_values)[0], ") -> ", $HT->datetime, "\n";
print "\n";

# Rosh HaShana (Jewish New Year) Eve 2003/5764
$HT = new DateTime::Calendar::Hebrew(
	year   => 5763,
	month  => 6,
	day    => 29,
	hour   => 22,
	minute => 30,
);
$DT = DateTime->from_object(object => $HT);

# 5764/07/01, because we haven't provided the necessary fields
print $HT->datetime, " (RD", ($HT->utc_rd_values)[0], ") -> ", $DT->datetime, "\n";

$HT->set(
	sunset => $sunset,
	time_zone => "America/New_York",
);
$DT = DateTime->from_object(object => $HT);

# 5764/07/02 b/c 10:30pm is always after sunset in NYC.
print $HT->datetime, " (RD", ($HT->utc_rd_values)[0], ") -> ", $DT->datetime, "\n";

# Eve of Succos (Tabernacles), but the sunset-feature is still operative
$HT->set( day => 14 );
$DT = DateTime->from_object(object => $HT);

# 5764/07/15 b/c 10:30pm is always after sunset in NYC.
print $HT->datetime, " (RD", ($HT->utc_rd_values)[0], ") -> ", $DT->datetime, "\n";
exit;
