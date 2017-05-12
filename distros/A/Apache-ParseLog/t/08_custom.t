# 08_custom.t; CustomLog test

$| = 1; 
print "1..11\n"; 
my($test) = 1;
my($dir);
chomp($dir = `pwd`);

sub writeFile {
	my($file) = shift;
	local(*FH);
	open(FH, ">$file");
	return *FH;
}

# 1 create the conf dynamically
my($tempconf) = "$dir/t/samples/temp.conf";
$fh = writeFile($tempconf);
print $fh <<TEMP;
ServerRoot $dir
LogFormat "%h %l %u %t \\"%r\\" %>s %b \\"%{Referer}i -> %U\\" \\"%{User-Agent}i\\"" all
LogFormat "%t %v %a %f %s %p %P %T %U" weird
CustomLog t/samples/sample.all.log all
CustomLog t/samples/sample.weird.log weird
TEMP
close($fh);
-e $tempconf ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 2 load
use Apache::ParseLog;
my($base) = new Apache::ParseLog($tempconf);
ref $base ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 3 all
my($alllog) = $base->getCustomLog("all");
ref $alllog ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 4 URL
my(%URL) = $alllog->url();
$URL{'/images/buttons/three.gif'} == 1 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 5 user
my(%user) = $alllog->user();
$user{'-'} == 30 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 6 weird
my($weird) = $base->getCustomLog("weird");
ref $weird ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 7 addr
my(%addr) = $weird->addr();
$addr{'3.4.5.6'} == 8 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 8 filename
my(%filename) = $weird->filename();
$filename{'/usr/local/httpd/htdocs/'} == 3 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 9 ostatus
my(%ostatus) = $weird->ostatus();
$ostatus{'500 Internal Server Error'} == 2 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 10 sec
my(%sec) = $weird->sec();
$sec{'/somecgi/nph-somecgi.cgi'} == 2 ? print "ok $test\n" : print "not ok $test\n";
$test++;

# 11 proc
my(%proc) = $weird->proc();
$proc{'20372'} == 6 ? print "ok $test\n" : print "not ok $test\n";
$test++;

unlink $tempconf;
# end of 08_custom.t


