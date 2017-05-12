use DateTime::Calendar::Hebrew;
use DateTime::Duration;
print "1..1\n";

# the date of the destruction of the first temple in Jerusalem
my $HT = new DateTime::Calendar::Hebrew(
	year => 3339,
	month => 5,
	day => 9,
	hour => 12,
	minute => 45,
);

my $duration = DateTime::Duration->new( days => 75, hours => 48, minutes => 400, seconds => 30);

$HT2 = $HT->clone()->add_duration($duration)->subtract_duration($duration);
$HT3 = $HT->clone()->subtract_duration($duration)->add_duration($duration);

if($HT == $HT2 and $HT2 == $HT3) { print "ok\n"; }
else { print "not ok\n"; }

exit;
