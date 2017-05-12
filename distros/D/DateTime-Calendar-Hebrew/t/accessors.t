use DateTime::Calendar::Hebrew;
print "1..18\n";

# Israeli Independence Day
my $DT = new DateTime::Calendar::Hebrew(
	year => 5708,
	month => 2,
	day => 5,
	hour => 16,
	minute => 30,
	second => 0,
);

if($DT->month_name eq "Iyar") { print "ok\n"; }

if($DT->day_name eq "Friday") { print "ok\n"; }
else { print "not ok\n"; }

if($DT->year eq "5708") { print "ok\n"; }
else { print "not ok\n"; }

if($DT->month eq "2") { print "ok\n"; }
else { print "not ok\n"; }

if($DT->month_0 eq "1") { print "ok\n"; }
else { print "not ok\n"; }

if($DT->day_of_month eq "5") { print "ok\n"; }
else { print "not ok\n"; }

if($DT->day_of_month_0 eq "4") { print "ok\n"; }
else { print "not ok\n"; }

if($DT->day_of_week == "6") { print "ok\n"; }
else { print "not ok\n"; }

if($DT->day_of_week_0 == "5") { print "ok\n"; }
else { print "not ok\n"; }

if($DT->week_number == "6") { print "ok\n"; }
else { print "not ok\n"; }

if($DT->day_of_year == "035") { print "ok\n"; }
else { print "not ok\n"; }

if($DT->day_of_year_0 == "034") { print "ok\n"; }
else { print "not ok\n"; }

if($DT->ymd eq "5708-02-05") { print "ok\n"; }
else { print "not ok\n"; }

if($DT->mdy('.') eq "02.05.5708") { print "ok\n"; }
else { print "not ok\n"; }

if($DT->dmy(',') eq "05,02,5708") { print "ok\n"; }
else { print "not ok\n"; }

if($DT->hour == "16") { print "ok\n"; }
else { print "not ok\n"; }

if($DT->minute == "30") { print "ok\n"; }
else { print "not ok\n"; }

if($DT->second == "0") { print "ok\n"; }

exit;

