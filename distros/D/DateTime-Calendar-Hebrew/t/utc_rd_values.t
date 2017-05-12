use DateTime::Calendar::Hebrew;
print "1..1\n";

my $DT = new DateTime::Calendar::Hebrew(
	year => 1,
	month => 1,
	day => 1,
);

if(($DT->utc_rd_values)[0] == -1373249) { print "ok\n"; }
else { print "not ok\n"; }

