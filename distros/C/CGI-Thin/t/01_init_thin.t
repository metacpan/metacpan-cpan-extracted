# 01_init_thin.t; just to load CGI::Thin by using it

$|++; 
print "1..1\n";
my($test) = 1;

use CGI::Thin;
$loaded = 1;
$loaded ? print "ok $test\n" : print "not ok $test\n";
$test++;

# end of 01_init_thin.t

