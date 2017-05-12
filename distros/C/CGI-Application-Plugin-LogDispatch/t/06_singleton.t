use Test::More tests => 8;
BEGIN { use_ok('CGI::Application::Plugin::LogDispatch') };

use lib './t';
use strict;

eval {
  require Class::ISA;
  Class::ISA->import;
};
 
if ($@) {
  plan skip_all => "Class::ISA required for Singleton support";
  exit;
}

$ENV{CGI_APP_RETURN_ONLY} = 1;

use TestAppSingleton;
my $t1_obj = TestAppSingleton->new();
my $t1_output = $t1_obj->run();

my $logoutput = ${$TestAppSingleton::HANDLE};

unlike($logoutput, qr/log singleton debug/, 'no debug message');
like($logoutput, qr/log singleton info/, 'logged info message');

my $t2_obj = TestAppSingleton::Sub->new();
my $t2_output = $t2_obj->run();

$logoutput = ${$TestAppSingleton::Sub::HANDLE};

like($logoutput, qr/log singleton infoEXTRA/, 'logged info messageEXTRA');
unlike($logoutput, qr/info[^E]/, 'old info message not there');

my $t3_obj = TestAppSingleton::Sub2->new();
my $t3_output = $t3_obj->run();

$logoutput = ${$TestAppSingleton::HANDLE};

like($logoutput, qr/log singleton info/, 'old info message is there');
like($logoutput, qr/log subsingleton info/, 'logged info message in subclass');

TestAppSingleton->log->info('class info message');
$logoutput = ${$TestAppSingleton::HANDLE};

like($logoutput, qr/class info message/, 'class method');

