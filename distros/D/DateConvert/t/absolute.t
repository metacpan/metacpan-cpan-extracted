#!perl -w

use Date::Convert;

print "1..3\n";

$n=1;

$date=new Date::Convert::Absolute(2450526);
if ($date->date == 2450526)
    {print "ok $n\n"} else 
    {print "not ok $n\n"}
$n++;

if ($date->date_string eq "2450526")
    {print "ok $n\n"} else 
    {print "not ok $n\n"}
$n++;

convert Date::Convert::Hebrew $date;
if ($date->date_string eq "5757 Adar II 9")
    {print "ok $n\n"} else 
    {print "not ok $n\n"}
$n++;

