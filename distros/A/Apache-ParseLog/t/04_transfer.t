# 04_trans.t; TransferLog report test

$| = 1; 
print "1..11\n"; 
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
					  transferlog  => "$dir/t/samples/sample.access.log");
ref $base ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 3 tlog
my($tlog) = $base->getTransferLog();
ref $tlog ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 4 hit
my(%hit) = $tlog->hit();
$hit{'Total'} == 30 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 5, 6 host
my(%host) = $tlog->host();
exists($host{'other.domain.net'}) ? print "ok $test\n" : print "not ok $test\n";
$test++;

$host{'another.domain.org'} == 10 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 7 hitbydate
my(%hitbydate) = $tlog->hitbydate();
scalar(keys %hitbydate) == 3 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 8 visitorbydate
my(%visitorbydate) = $tlog->visitorbydate();
$visitorbydate{'08/27/1998'} == 2 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 9 file
my(%file) = $tlog->file();
exists($file{'/perl/'}) ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 10 lstatus
my(%lstatus) = $tlog->lstatus();
$lstatus{'304 Not Modified'} == 9 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 11 byte
my(%byte) = $tlog->byte();
$byte{'Total'} == 71384 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# end of 04_trans.t


