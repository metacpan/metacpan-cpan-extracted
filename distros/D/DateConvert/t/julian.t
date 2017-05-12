#!perl -w

use Date::Convert;

print "1..9\n";

$n=1;

$a=1757642;
$date=new Date::Convert::Absolute($a);
if ($date->date == 1757642)
    {print "ok $n\n"} else 
    {print "not ok $n\n"}
$n++;

convert Date::Convert::Julian $date;
if ($date->date_string eq "100 Feb 29")
    {print "ok $n\n"} else 
    {print "not ok $n\n"}
$n++;

convert Date::Convert::Absolute $date;
if ($date->date_string eq "1757642")
    {print "ok $n\n"} else 
    {print "not ok $n\n"}
$n++;

$date=new Date::Convert::Gregorian(1997, 4, 15);
convert Date::Convert::Julian $date;
if ($date->date_string eq "1997 Apr 2")
    {print "ok $n\n"} else 
    {print "not ok $n\n"}
$n++;


convert Date::Convert::Gregorian $date;
if ($date->date_string eq "1997 Apr 15")
    {print "ok $n\n"} else 
    {print "not ok $n\n"}
$n++;

$date=new Date::Convert::Julian(1999, 9, 25);
if ($date->date_string eq "1999 Sep 25")
    {print "ok $n\n"} else
    {print "no ok $n\n"}
$n++;

convert Date::Convert::Gregorian $date;
if ($date->date_string eq "1999 Oct 8")
    {print "ok $n\n"} else
    {print "no ok $n\n"}
$n++;

$date=new Date::Convert::Julian(1999, 12, 18);
convert Date::Convert::Gregorian $date;
if ($date->date_string eq "1999 Dec 31")
    {print "ok $n\n"} else
    {print "no ok $n\n"}
$n++;

$date=new Date::Convert::Julian(1999, 12, 19);
convert Date::Convert::Gregorian $date;
if ($date->date_string eq "2000 Jan 1")
    {print "ok $n\n"} else
    {print "no ok $n\n"}
$n++;


