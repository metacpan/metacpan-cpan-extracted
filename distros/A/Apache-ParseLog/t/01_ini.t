# 01_ini.t; just to load Apache::ParseLog by using it

$|++; 
print "1..1\n";
my($test) = 1;

# 1 load
use Apache::ParseLog;
my($loaded) = 1;
$loaded ? print "ok $test\n" : print "not ok $test\n";
$test++;

# end of 01_ini.t

