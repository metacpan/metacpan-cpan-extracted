use Test::More tests => 3;
BEGIN { use_ok('CGI::Application::Plugin::LogDispatch') };

use lib './t';
use strict;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use TestAppBasic;
my $t1_obj = TestAppBasic->new();
my $t1_output = $t1_obj->run();

my $logoutput = ${$t1_obj->{__LOG_MESSAGES}->{HANDLE}};

unlike($logoutput, qr/log debug/, 'no debug message');
like($logoutput, qr/log info/, 'logged info message');


