# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}
use Date::Christmas;
$loaded = 1;
print "ok 1\n";

print "Christmas day 1985 ";
$date = christmasday(1985);    
if ($date eq 'Wednesday')      {
        print "ok 2\n";
}
else {
        print "not ok 2\n";
}

print "Christmas day 1800 ";
$date = christmasday(1800);       
if ($date eq 'Thursday')      {
        print "ok 3\n";
}
else {
        print "not ok 3\n";
}
print "Christmas day 1929 ";
$date = christmasday(1929);       
if ($date eq 'Wednesday')      {
        print "ok 4\n";
}
else {
        print "not ok 4\n";
}
print "Christmas day 2001 ";
$date = christmasday(2001);       
if ($date eq 'Tuesday')      {
        print "ok 5\n";
}
else {
        print "not ok 5\n";
}
print "Christmas day 1969 ";
$date = christmasday(1969);       
if ($date eq 'Thursday')      {
        print "ok 6\n";
}
else {
        print "not ok 6\n";
}
print "Christmas day 2032 ";
$date = christmasday(2032);       
if ($date eq 'Saturday')      {
        print "ok 7\n";
}
else {
        print "not ok 7\n";
}
