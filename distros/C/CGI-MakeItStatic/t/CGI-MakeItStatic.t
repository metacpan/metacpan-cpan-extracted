use Test::More;

use Cwd;
use CGI;

$| = 1;

if($^O =~/linux/){
  plan 'no_plan';
}else{
  plan tests => 1;
  use_ok('CGI::MakeItStatic');
  exit;
}

use_ok('CGI::MakeItStatic');

mkdir("/tmp/CGI-MakeItStatic") or die "cannot create directory /tmp/CGI-MakeItStatic";

my $result;

system("env REQUEST_METHOD=GET QUERY_STRING='hoge=1' perl -Iblib/lib t/test.pl > /dev/null");
my $dir = CGI::escape(Cwd::getcwd());
$result = `grep hoge=1  /tmp/CGI-MakeItStatic/$dir%2Ft%2Ftest.pl%3Fhoge%3D1`;
ok($result =~/hoge=1/ ? 1 : 0);

# first
system("env REQUEST_METHOD=GET QUERY_STRING='month=0&times=1' perl -Iblib/lib t/test2.pl > /dev/null");
$result = `grep month=0   /tmp/CGI-MakeItStatic/month%3D00`;
ok( $result =~/month=0/ ? 1 : 0);

$result = `grep times=1   /tmp/CGI-MakeItStatic/month%3D00`;
ok( $result =~/times=1/ ? 1 : 0);

# it must be static (times=1)
system("env REQUEST_METHOD=GET QUERY_STRING='month=0&times=2' perl -Iblib/lib t/test2.pl > /dev/null");
$result = `grep times=1   /tmp/CGI-MakeItStatic/month%3D00`;
ok($result =~/times=1/ ? 1 : 0);

# recreate (times=3)
system("env REQUEST_METHOD=GET QUERY_STRING='month=0&times=3&renew=1' perl -Iblib/lib t/test2.pl > /dev/null");
$result = `grep times=3   /tmp/CGI-MakeItStatic/month%3D00`;
ok( $result =~/times=3/ ? 1 : 0);

# month = 1 is forbidden
system("env REQUEST_METHOD=GET QUERY_STRING='month=1&times=4' perl -Iblib/lib t/test2.pl > /dev/null");
ok($result = ! -e "/tmp/CGI-MakeItStatic/month%3D01");

# recreate but forbidden
system("env REQUEST_METHOD=GET QUERY_STRING='month=1&times=5&renew=1' perl -Iblib/lib t/test2.pl");
ok($result = ! -e "/tmp/CGI-MakeItStatic/month%3D01");

# first
system("env REQUEST_METHOD=GET QUERY_STRING='month=2&times=6' perl -Iblib/lib t/test2.pl > /dev/null");
$result = `grep month=2   /tmp/CGI-MakeItStatic/month%3D02`;
ok( $result =~/month=2/ ? 1 : 0);
$result = `grep times=6   /tmp/CGI-MakeItStatic/month%3D02`;
ok( $result =~/times=6/ ? 1 : 0);

# recreate, but forbidnew
system("env REQUEST_METHOD=GET QUERY_STRING='month=2&times=7&renew=1' perl -Iblib/lib t/test2.pl > /dev/null");
$result = `grep month=2   /tmp/CGI-MakeItStatic/month%3D02`;
ok( $result =~/month=2/ ? 1 : 0);
$result = `grep times=6   /tmp/CGI-MakeItStatic/month%3D02`;
ok( $result =~/times=6/ ? 1 : 0);

# recreate and noprint option 1
system("env REQUEST_METHOD=GET QUERY_STRING='month=0&times=8&renew=1' perl -Iblib/lib t/test2.pl 1 > /tmp/CGI-MakeItStatic/output");
$result = `grep month=0   /tmp/CGI-MakeItStatic/month%3D00`;
ok( $result =~/month=0/ ? 1 : 0);
$result = `grep times=8   /tmp/CGI-MakeItStatic/month%3D00`;
ok( $result =~/times=8/ ? 1 : 0);
ok(-z '/tmp/CGI-MakeItStatic/output');

# recreate and noprint option 1 and output by pl insted of module
system("env debug=1 REQUEST_METHOD=GET QUERY_STRING='month=0&times=9&renew=1' perl -Iblib/lib t/test2.pl 2 > /tmp/CGI-MakeItStatic/output");
$result = `grep month=0   /tmp/CGI-MakeItStatic/month%3D00`;
ok( $result =~/month=0/ ? 1 : 0);
$result = `grep times=9   /tmp/CGI-MakeItStatic/month%3D00`;
ok( $result =~/times=9/ ? 1 : 0);
ok(!-z '/tmp/CGI-MakeItStatic/output');

system("rm /tmp/CGI-MakeItStatic/*");
system("rmdir /tmp/CGI-MakeItStatic");
