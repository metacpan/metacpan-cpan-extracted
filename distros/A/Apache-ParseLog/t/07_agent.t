# 07_agent.t; AgentLog test

$| = 1; 
print "1..9\n"; 
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
                      agentlog    => "$dir/t/samples/sample.agent.log");
ref $base ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 4 agentlog
my($alog) = $base->getAgentLog();
ref $alog ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 5 uagent
my(%uagent) = $alog->uagent();
$uagent{'Mozilla/4.05 [en] (X11; I; SunOS 5.5.1 sun4u)'} == 1 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 6 uaversion
my(%uaversion) = $alog->uaversion();
$uaversion{'Mozilla/4.03'} == 14 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 7 browser
my(%browser) = $alog->browser();
$browser{'MSIE 4.01'} == 7 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 8 platform
my(%platform) = $alog->platform();
$platform{'Win95'} == 37 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 9 browserbyos
my(%browserbyos) = $alog->browserbyos();
$browserbyos{'AOL 4.0 (Windows 98)'} == 2 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# end of 07_agent.t


