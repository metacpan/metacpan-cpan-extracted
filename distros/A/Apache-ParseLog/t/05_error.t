# 05_error.t; ErrorLog test

$| = 1; 
print "1..9\n"; 
my($test) = 1;
my($dir);

chomp($dir = `pwd`);
my($conf) = "$dir/t/samples/sample.httpd.conf";

# 1 load
use Apache::ParseLog;
my($base) = new Apache::ParseLog($conf);
ref $base ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 2 config
$base = $base->config(servername   => "www.test.com",
					  serverroot   => $dir,
					  serveradmin  => "you\@test.com",
					  errorlog  => "$dir/t/samples/sample.error.log");
ref $base ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 3 elog
my($elog) = $base->getErrorLog();
ref $elog ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 4 count
my(%hit) = $elog->count();
$hit{'Total'} == 68 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 5 allbydate
my(%allbydate) = $elog->allbydate();
exists($allbydate{'08/04/1998'}) ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 6 errorbydate
my(%errorbydate) = $elog->errorbydate();
$errorbydate{'07/23/1998'} == 6 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 7 noticebydate
my(%noticebydate) = $elog->noticebydate();
$noticebydate{'06/20/1998'} == 2 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 8 warnbydate
my(%warnbydate) = $elog->warnbydate();
$warnbydate{'09/21/1998'} == 4 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 9 allmessage
my(%allmessage) = $elog->allmessage();
exists($allmessage{'child process 5 still did not exit, sending a SIGTERM'}) ? print "ok $test\n" : print "not ok $test\n";
$test++;

# end of 05_error.t


