# 02_new.t; test loading and configuring the base object

$| = 1; 
print "1..3\n"; 
my($test) = 1;
my($dir);

chomp($dir = `pwd`);
my($conf) = "$dir/t/samples/sample.httpd.conf";

# 1 load
use Apache::ParseLog;
my($new) = new Apache::ParseLog();
ref $new ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 2 new
my($base) = new Apache::ParseLog($conf);
ref $base ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 3 config
$base = $base->config(servername  => "www.test.com",
					serverroot  => $dir,
					serveradmin => "you\@test.com",
					transferlog => "$dir/t/samples/sample.transfer.log");
ref $base ? print "ok $test\n" : print "not ok $test\n";
$test++;

# end of 02_new.t


