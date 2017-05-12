use DateTime::Calendar::Hebrew;
print "1..1\n";

# the date of the destruction of the first temple in Jerusalem
my $DT = new DateTime::Calendar::Hebrew(
	year => 3339,
	month => 5,
	day => 9,
);

if($DT and $DT->isa("DateTime::Calendar::Hebrew")) { print "ok\n"; }
else { print "not ok\n"; }

exit;
