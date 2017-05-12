#!perl -w

use Date::Convert;

print "1..6\n";

$n=1;

@a=(5730, 3, 2);
@b=(new Date::Convert::Hebrew @a)->date;
if ("@a" eq "@b")
    {print "ok $n\n"} else 
    {print "not ok $n\n"}
$n++;

@a=(5720, 8, 29);
@b=(new Date::Convert::Hebrew @a)->date;
if ("@a" eq "@b")
    {print "ok $n\n"} else 
    {print "not ok $n\n"}
$n++;

@a=(5755, 9, 20);
@b=(new Date::Convert::Hebrew @a)->date;
if ("@a" eq "@b")
    {print "ok $n\n"} else 
    {print "not ok $n\n"}
$n++;

@a=(5730, 3, 2);
@b=(new Date::Convert::Gregorian @a)->date;
if ("@a" eq "@b")
    {print "ok $n\n"} else 
    {print "not ok $n\n"}
$n++;

@a=(5730, 3, 2);
@b=(new Date::Convert::Gregorian @a)->date;
if ("@a" eq "@b")
    {print "ok $n\n"} else 
    {print "not ok $n\n"}
$n++;

@a=(5730, 3, 2);
@b=(new Date::Convert::Gregorian @a)->date;
if ("@a" eq "@b")
    {print "ok $n\n"} else 
    {print "not ok $n\n"}
$n++;


