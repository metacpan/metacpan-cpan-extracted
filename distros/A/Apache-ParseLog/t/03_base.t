# 03_base.t; check the base methods

$|++;
print "1..11\n";
my($test) = 1;
my($dir);

chomp($dir = `pwd`);
my($conf) = "$dir/t/samples/sample.httpd.conf";

# 1
use Apache::ParseLog;
my($base) = new Apache::ParseLog($conf);
ref $base ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 2 version
my($version) = $base->Version();
$version eq "1.02" ? print "ok $test\n": print "not ok $test\n";
$test++;

# 3 serverroot
my($root) = $base->serverroot();
$root eq "/usr/local/httpd" ? print "ok $test\n": print "not ok $test\n"; 
$test++;

# 4 servername
my($name) = $base->servername();
$name eq "www.sample.org" ? print "ok $test\n": print "not ok $test\n";
$test++;

# 5 httpport
my($port) = $base->httpport();
$port eq "80" ? print "ok $test\n": print "not ok $test\n";
$test++;

# 6 serveradmin
my($admin) = $base->serveradmin();
$admin eq "webmaster\@sample.org" ? print "ok $test\n": print "not ok $test\n";
$test++;

# 7 trasnferlog
my($tlog) = $base->transferlog();
$tlog eq "$root/logs/transfer.log" ? print "ok $test\n": print "not ok $test\n";
$test++;

# 8 errorlog
my($elog) = $base->errorlog();
$elog eq "$root/logs/error_log" ? print "ok $test\n": print "not ok $test\n";
$test++;

# 9 agentlog
my($alog) = $base->agentlog();
$alog eq "$root/logs/agent.log" ? print "ok $test\n": print "not ok $test\n";
$test++;

# 10 refererlog
my($rlog) = $base->refererlog();
$rlog eq "$root/logs/referer.log" ? print "ok $test\n": print "not ok $test\n";
$test++;

# 11 customlog
my(@clog) = sort $base->customlog();
$clog[$#clog] eq "weird" ? print "ok $test\n": print "not ok $test\n";
$test++;

# end of 03_base.t
