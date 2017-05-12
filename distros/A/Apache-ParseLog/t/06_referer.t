# 06_referer.t; RefererLog test

$| = 1; 
print "1..7\n"; 
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
my($nb) = $base->config(servername  => "www.test.com",
					  serverroot  => $dir,
					  serveradmin => "you\@test.com",
					  refererlog  => "$dir/t/samples/sample.referer.log");
ref $nb ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 3 refererlog
my($rlog) = $nb->getRefererLog();
ref $rlog ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 4 referer
my(%referer) = $rlog->referer();
$referer{'user.one.com'} == 8 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 5 referer
$referer{'bookmark'} == 7 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 6 refererdetail
my(%detail) = $rlog->refererdetail();
$detail{'http://user.two.net/ -> /perl/'} == 1 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 7 refererdetail
$detail{'http://user.one.com/ -> /icons/text.gif'} == 2 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# end of 06_referer.t


