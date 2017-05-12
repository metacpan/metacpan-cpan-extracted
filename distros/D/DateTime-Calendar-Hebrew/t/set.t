use DateTime::Calendar::Hebrew;
print "1..1\n";

# the date of the destruction of the second temple in Jerusalem
my $DT = new DateTime::Calendar::Hebrew(
	year => 3829,
	month => 5,
	day => 9,
);

# Rosh Hashana of this year
$DT->set(
	year => 5763,
	month => 1,
	day => 1,
	hour => 0,
	minute => 0,
	second => 0,
);

if(($DT->utc_rd_values)[0] == 731308) { print "ok\n"; }
else { print "not ok\n"; }
