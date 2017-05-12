use Test::More tests => 4;

use lib './t';
use strict;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use TestAppMultiple;
my $t1_obj = TestAppMultiple->new();
my $t1_output = $t1_obj->run();

my $logoutput = ${$t1_obj->{__LOG_MESSAGES}->{HANDLE}};
my $logoutput2 = ${$t1_obj->{__LOG_MESSAGES}->{HANDLE2}};

like($logoutput, qr/log debug/, 'logged debug message');
like($logoutput, qr/log info/, 'logged info message');

unlike($logoutput2, qr/log debug/, 'no debug message');
like($logoutput2, qr/log info/, 'logged info message');
