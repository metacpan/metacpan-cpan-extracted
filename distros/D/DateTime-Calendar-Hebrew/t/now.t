use DateTime::Calendar::Hebrew;
print "1..1\n";

my $DT = DateTime::Calendar::Hebrew->now;

if($DT and $DT->isa("DateTime::Calendar::Hebrew")) { print "ok\n"; }
else { print "not ok\n"; }

exit;
