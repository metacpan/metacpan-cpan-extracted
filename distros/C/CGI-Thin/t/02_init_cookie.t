# 02_init_cookie.t; just to load CGI::Thin::Cookies by using it

$|++; 
print "1..1\n";
my($test) = 1;

use CGI::Thin::Cookies;
$loaded = 1;
$loaded ? print "ok $test\n" : print "not ok $test\n";
$test++;

# end of 02_init_cookie.t

