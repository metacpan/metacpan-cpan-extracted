use Test::More;

use lib './t';
use strict;

eval {
  require Sub::WrapPackages;
};
 
if ($@) {
  plan skip_all => "Sub::WrapPackages required to test method execution logging";
  exit;
}
plan tests => 5;
$ENV{CGI_APP_RETURN_ONLY} = 1;

use TestAppLogMethods;
my $t1_obj = TestAppLogMethods->new();
my $t1_output = $t1_obj->run();

my $logoutput = ${$t1_obj->{__LOG_MESSAGES}->{HANDLE}};

like($logoutput, qr/log debug/, 'logged debug message');
like($logoutput, qr/calling TestAppLogMethods::test_mode\(TestAppLogMethods=HASH/, "logged call to 'test_mode'");
like($logoutput, qr/returning from TestAppLogMethods::test_mode \(test_mode return value\)/, "logged return from 'test_mode'");
like($logoutput, qr/calling TestAppLogMethods::other_method\(param1, param2\)/, "logged call to 'other_method'");
like($logoutput, qr/returning from TestAppLogMethods::other_method \(other_method return value\)/, "logged return from 'other_method'");

