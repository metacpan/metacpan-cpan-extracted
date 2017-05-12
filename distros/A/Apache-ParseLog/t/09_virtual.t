# 09_virtual.t; VirtualHost test

$| = 1; 
print "1..7\n"; 
my($test) = 1;
my($dir);

chomp($dir = `pwd`);
my($conf) = "$dir/t/samples/sample.httpd.conf";
my($vh) = "www.virtual.com";

# 1 load
use Apache::ParseLog;
my($base) = new Apache::ParseLog($conf, $vh);
ref $base ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 2 config
$base = $base->config(transferlog => "$dir/t/samples/sample.virtual.log");
ref $base ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 3 servername
my($servername) = $base->servername();
$servername eq "www.virtual.com" ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 4 serveradmin
my($serveradmin) = $base->serveradmin();
$serveradmin eq "webmaster\@virtual.com" ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 5 errorlog
my($errorlog) = $base->errorlog();
$errorlog eq "/usr/local/httpd/logs/virtual.error.log" ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 6 customlog
my(@customlog) = $base->customlog();
scalar(@customlog) == 1 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 7 transferlog
my($tlog) = $base->getTransferLog();
ref $tlog ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 8 


# end of 09_virtual.t


