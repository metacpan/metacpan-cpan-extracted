use DateTime::Calendar::Hebrew;
use DateTime;
print "1..1\n";

my $birthday = new DateTime(
	year => 1974,
	month => 12,
	day => 19,
);
my $HT = DateTime::Calendar::Hebrew->from_object(object => $birthday);
my $DT = DateTime->from_object(object => $HT);

if($HT and $HT->isa("DateTime::Calendar::Hebrew") and $birthday->datetime eq $DT->datetime) { print "ok\n"; }
else { print "not ok\n"; }

exit;
