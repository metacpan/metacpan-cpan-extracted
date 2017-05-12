#!perl -w

use Date::Convert;

print "1..4\n";

$n=1;

$date=new Date::Convert::Gregorian(1974, 11, 27);

convert Date::Convert::Hebrew $date;
if ($date->date_string eq "5735 Kislev 13") 
    {print "ok $n\n"} else 
    {print "not ok $n\n"}
$n++;

convert Date::Convert::Gregorian $date;
if ($date->date_string eq "1974 Nov 27")
    {print "ok $n\n"} else 
    {print "not ok $n\n"}
$n++;



$guy = new Date::Convert::Hebrew (5756, 7, 8);

convert Date::Convert::Gregorian $guy;
if ($guy->date_string eq "1995 Oct 2")
    {print "ok $n\n"} else 
    {print "not ok $n\n"}
$n++;

convert Date::Convert::Hebrew $guy;
if ($guy->date_string eq "5756 Tishrei 8")
    {print "ok $n\n"} else 
    {print "not ok $n\n"}
$n++;

